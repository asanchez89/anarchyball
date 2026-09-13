class_name LevelBuilder
extends Node2D

signal level_built(spec: LevelSpec)
signal slice_completed()

@export_file("*.json") var level_spec_path: String
@export var content_catalog: ContentCatalog
@export var build_on_ready: bool = true
@export var start_in_menu: bool = true

var registry := ContentRegistry.new()
var last_validation: LevelValidationResult
var loaded_spec: LevelSpec
var telemetry: LocalRunTelemetry
var _player: PlayerController
var _spawn_position: Vector2
var _fall_reset_y: float = INF
var _checkpoint := RunCheckpointState.new()
var _collected_reward_ids: Array[StringName] = []
var _hud: GeneratedLevelHud
var _flow: SliceFlowController
var _audio: FeedbackTone
var _accessibility: AccessibilitySettings
var _skip_start_menu_once: bool = false
var _encounter_actors: Dictionary = {}


func _ready() -> void:
	_accessibility = AccessibilityStore.load_settings()
	if build_on_ready:
		build_from_file(level_spec_path, content_catalog)


func _process(_delta: float) -> void:
	if _player == null or _player.global_position.y <= _fall_reset_y:
		return
	telemetry.record_event(&"defeat", {"cause": "fall", "position": _vector_payload(_player.global_position)})
	_retry_to_checkpoint()


func restart_run() -> void:
	_skip_start_menu_once = true
	build_from_file(level_spec_path, content_catalog)


func activate_checkpoint(checkpoint_id: StringName, position: Vector2) -> void:
	_capture_checkpoint(checkpoint_id, position)


func retry_from_checkpoint() -> void:
	_retry_to_checkpoint()


func build_from_file(path: String, catalog: ContentCatalog) -> LevelValidationResult:
	if _accessibility == null:
		_accessibility = AccessibilityStore.load_settings()
	_clear_generated()
	if not registry.register_catalog(catalog, catalog.resource_path if catalog != null else "<catalog>"):
		last_validation = LevelValidationResult.new(path)
		for error: String in registry.errors():
			last_validation.add_error(&"invalid_catalog", "catalog", error)
		_show_errors(last_validation)
		return last_validation
	var load_result := LevelSpecLoader.load_file(path)
	if not load_result.is_success():
		last_validation = LevelValidationResult.new(path)
		for error: String in load_result.errors:
			last_validation.add_error(&"load_error", "root", error)
		_show_errors(last_validation)
		return last_validation
	loaded_spec = load_result.spec
	last_validation = LevelValidator.validate(loaded_spec, registry)
	if not last_validation.is_valid():
		_show_errors(last_validation)
		return last_validation
	_build_valid_spec(loaded_spec)
	return last_validation


func _build_valid_spec(spec: LevelSpec) -> void:
	var generated := Node2D.new()
	generated.name = "Generated"
	add_child(generated)
	telemetry = LocalRunTelemetry.new()
	telemetry.name = "RunTelemetry"
	generated.add_child(telemetry)
	telemetry.configure(spec.level_id(), StringName(String(spec.data.get("class_loadout_id", ""))))
	_audio = FeedbackTone.new()
	_audio.name = "FeedbackAudio"
	generated.add_child(_audio)
	_build_backdrop(spec, generated)
	_build_platforms(spec, generated)
	var player := _build_player(spec, generated)
	_player = player
	_spawn_position = player.global_position
	var bounds := spec.data.get("bounds") as Dictionary
	_fall_reset_y = float(bounds.get("height")) + 120.0
	_build_sections(spec, generated)
	_build_encounters(spec, generated)
	_build_resources(spec, generated)
	_build_gates(spec, generated)
	_build_rule_objects(spec, generated)
	_build_encounter_observers(spec, generated)
	_build_checkpoints(spec, generated)
	_build_exit(spec, generated)
	_build_rule_label(spec, generated)
	_build_debug_hud(spec, player, generated)
	_connect_telemetry(player, generated)
	_capture_checkpoint(&"level_start", _spawn_position)
	_build_slice_flow(spec, generated)
	level_built.emit(spec)


func _build_backdrop(spec: LevelSpec, parent: Node2D) -> void:
	var bounds := spec.data.get("bounds") as Dictionary
	var backdrop := Polygon2D.new()
	backdrop.name = "Backdrop"
	backdrop.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(float(bounds.get("width")), 0.0),
		Vector2(float(bounds.get("width")), float(bounds.get("height"))),
		Vector2(0.0, float(bounds.get("height"))),
	])
	backdrop.color = _rule_color(spec)
	parent.add_child(backdrop)


func _build_platforms(spec: LevelSpec, parent: Node2D) -> void:
	var container := Node2D.new()
	container.name = "Platforms"
	parent.add_child(container)
	for platform_value: Variant in spec.data.get("platforms") as Array:
		var data := platform_value as Dictionary
		var platform := DebugPlatform.new()
		platform.name = String(data.get("id"))
		platform.size = Vector2(float(data.get("width")), float(data.get("height")))
		platform.position = Vector2(
			float(data.get("x")) + platform.size.x * 0.5,
			float(data.get("y")) + platform.size.y * 0.5
		)
		if not bool(data.get("required", true)):
			platform.edge_color = Color("a987d4")
		container.add_child(platform)
		if not bool(data.get("required", true)):
			var trigger := RouteTrigger.new()
			trigger.name = "%sRoute" % String(data.get("id"))
			trigger.position = Vector2(platform.position.x, float(data.get("y")) - 45.0)
			trigger.size = Vector2(platform.size.x, 90.0)
			trigger.collision_layer = 0
			trigger.collision_mask = 2
			trigger.telemetry = telemetry
			for tag_value: Variant in data.get("route_tags", []) as Array:
				trigger.route_tags.append(StringName(String(tag_value)))
			container.add_child(trigger)


func _build_player(spec: LevelSpec, parent: Node2D) -> PlayerController:
	var scene := load("res://src/actors/player/player.tscn") as PackedScene
	var player := scene.instantiate() as PlayerController
	player.name = "Player"
	var spawn := spec.data.get("player_spawn") as Dictionary
	player.position = Vector2(float(spawn.get("x")), float(spawn.get("y")))
	var bounds := spec.data.get("bounds") as Dictionary
	var camera := player.get_node("PlayerCamera") as PlayerCamera
	camera.shake_enabled = _accessibility.screen_shake_enabled
	camera.limit_right = int(bounds.get("width"))
	camera.limit_bottom = int(bounds.get("height"))
	parent.add_child(player)
	var class_id := StringName(String(spec.data.get("class_loadout_id")))
	var loadout := registry.get_definition(ContentRegistry.Kind.CLASS_LOADOUT, class_id) as ClassLoadout
	if loadout != null and &"ability_defensive_response" in loadout.ability_ids:
		var response := ContractorDefensiveResponse.new()
		response.name = "ContractorDefensiveResponse"
		response.profile = load("res://data/classes/defensive_response_profile.tres") as DefensiveResponseProfile
		player.add_child(response)
	return player


func _build_sections(spec: LevelSpec, parent: Node2D) -> void:
	var bounds := spec.data.get("bounds") as Dictionary
	for section_value: Variant in spec.data.get("sections") as Array:
		var data := section_value as Dictionary
		var trigger := SectionTrigger.new()
		trigger.name = String(data.get("id"))
		trigger.section_id = StringName(String(data.get("id")))
		var from_x := float(data.get("from_x", 0.0))
		var to_x := float(data.get("to_x", bounds.get("width")))
		trigger.size = Vector2(to_x - from_x, float(bounds.get("height")))
		trigger.position = Vector2((from_x + to_x) * 0.5, trigger.size.y * 0.5)
		trigger.collision_layer = 0
		trigger.collision_mask = 2
		trigger.telemetry = telemetry
		parent.add_child(trigger)


func _build_encounters(spec: LevelSpec, parent: Node2D) -> void:
	var container := Node2D.new()
	container.name = "Encounters"
	parent.add_child(container)
	for placement_value: Variant in spec.data.get("encounters") as Array:
		var placement := placement_value as Dictionary
		var encounter_id := StringName(String(placement.get("id")))
		var encounter_actors: Array[CombatTarget] = []
		var definition := registry.get_definition(
			ContentRegistry.Kind.ENCOUNTER_DEFINITION,
			StringName(String(placement.get("definition_id")))
		) as EncounterDefinition
		var protected_actor: CombatTarget
		if not definition.protected_archetype_id.is_empty():
			var protected_archetype := registry.get_definition(
				ContentRegistry.Kind.ENEMY_ARCHETYPE,
				definition.protected_archetype_id
			) as EnemyArchetype
			protected_actor = _instantiate_actor(protected_archetype, placement, -1)
			protected_actor.name = String(protected_archetype.content_id)
			protected_actor.position.x -= 115.0
			container.add_child(protected_actor)
		for index: int in definition.enemy_archetype_ids.size():
			var archetype := registry.get_definition(
				ContentRegistry.Kind.ENEMY_ARCHETYPE,
				definition.enemy_archetype_ids[index]
			) as EnemyArchetype
			var actor := _instantiate_actor(archetype, placement, index)
			container.add_child(actor)
			encounter_actors.append(actor)
			if protected_actor != null and actor.behavior == CombatTarget.Behavior.ATTACK_THIRD_PARTY:
				actor.protected_target_id = protected_actor.stable_id
				actor.protected_target_path = actor.get_path_to(protected_actor)
		_encounter_actors[encounter_id] = encounter_actors


func _instantiate_actor(archetype: EnemyArchetype, placement: Dictionary, index: int) -> CombatTarget:
	var scene := load(archetype.actor_scene_path) as PackedScene
	var actor := scene.instantiate() as CombatTarget
	actor.name = String(archetype.content_id)
	actor.position = Vector2(float(placement.get("x")) + maxf(index, 0) * 130.0, float(placement.get("y")))
	actor.apply_archetype(archetype)
	actor.player_path = NodePath("../../Player")
	return actor


func _build_resources(spec: LevelSpec, parent: Node2D) -> void:
	var container := Node2D.new()
	container.name = "Resources"
	parent.add_child(container)
	for resource_value: Variant in spec.data.get("resources") as Array:
		var data := resource_value as Dictionary
		var pickup := DebugPickup.new()
		pickup.name = String(data.get("id"))
		pickup.pickup_id = StringName(String(data.get("id")))
		pickup.ownership = StringName(String(data.get("ownership")))
		pickup.position = Vector2(float(data.get("x")), float(data.get("y")))
		pickup.collected.connect(_on_pickup_collected)
		container.add_child(pickup)


func _build_gates(spec: LevelSpec, parent: Node2D) -> void:
	var container := Node2D.new()
	container.name = "Gates"
	parent.add_child(container)
	var loadout := registry.get_definition(
		ContentRegistry.Kind.CLASS_LOADOUT,
		StringName(String(spec.data.get("class_loadout_id")))
	) as ClassLoadout
	for gate_value: Variant in spec.data.get("gates", []) as Array:
		var data := gate_value as Dictionary
		var gate := AccessGate.new()
		gate.name = String(data.get("id"))
		gate.gate_id = StringName(String(data.get("id")))
		gate.position = Vector2(float(data.get("x")), float(data.get("y")))
		gate.size = Vector2(float(data.get("width", 42.0)), float(data.get("height", 150.0)))
		gate.required_tag = StringName(String(data.get("required_tag", "")))
		gate.player_tags = loadout.interaction_tags.duplicate() if loadout != null else []
		gate.rule_text = String(data.get("label", "Acceso contractual"))
		gate.opened.connect(_on_gate_opened)
		container.add_child(gate)


func _build_rule_objects(spec: LevelSpec, parent: Node2D) -> void:
	var container := Node2D.new()
	container.name = "RuleObjects"
	parent.add_child(container)
	var rule_ids := spec.data.get("ideology_rule_ids") as Array
	if rule_ids.is_empty():
		return
	var rule := registry.get_definition(
		ContentRegistry.Kind.IDEOLOGY_RULE,
		StringName(String(rule_ids[0]))
	) as IdeologyRuleDefinition
	for object_value: Variant in spec.data.get("rule_objects", []) as Array:
		var data := object_value as Dictionary
		if StringName(String(data.get("hook_id"))) != IdeologyRuleDefinition.HOOK_OCCUPANCY_MACHINE:
			continue
		var machine := RuleStateObject.new()
		machine.name = String(data.get("id"))
		machine.rule_id = rule.content_id
		machine.object_id = StringName(String(data.get("id")))
		machine.interaction_tag = StringName(String(data.get("interaction_tag")))
		machine.machine_label = String(rule.parameters.get("machine_label", rule.display_name))
		machine.current_state = RuleStateObject.state_from_id(StringName(String(data.get("initial_state"))))
		machine.position = Vector2(float(data.get("x")), float(data.get("y")))
		var targets: Array[DebugPlatform] = []
		for target_value: Variant in data.get("target_platform_ids") as Array:
			var target := parent.get_node("Platforms/%s" % String(target_value)) as DebugPlatform
			targets.append(target)
		machine.configure_targets(targets)
		machine.state_changed.connect(_on_rule_state_changed)
		container.add_child(machine)


func _build_encounter_observers(spec: LevelSpec, parent: Node2D) -> void:
	var container := Node.new()
	container.name = "EncounterObservers"
	parent.add_child(container)
	for placement_value: Variant in spec.data.get("encounters") as Array:
		var placement := placement_value as Dictionary
		var encounter_id := StringName(String(placement.get("id")))
		var definition := registry.get_definition(
			ContentRegistry.Kind.ENCOUNTER_DEFINITION,
			StringName(String(placement.get("definition_id")))
		) as EncounterDefinition
		var actors: Array[CombatTarget] = []
		actors.assign(_encounter_actors.get(encounter_id, []))
		var rule_objects: Array[RuleStateObject] = []
		for object_id_value: Variant in placement.get("rule_object_ids", []) as Array:
			var rule_object := parent.get_node_or_null("RuleObjects/%s" % String(object_id_value)) as RuleStateObject
			if rule_object != null:
				rule_objects.append(rule_object)
		var observer := EncounterRuntimeObserver.new()
		observer.name = String(encounter_id)
		observer.configure(encounter_id, definition, actors, rule_objects)
		observer.resolved.connect(_on_encounter_resolved)
		container.add_child(observer)


func _build_checkpoints(spec: LevelSpec, parent: Node2D) -> void:
	var container := Node2D.new()
	container.name = "Checkpoints"
	parent.add_child(container)
	for checkpoint_value: Variant in spec.data.get("checkpoints", []) as Array:
		var data := checkpoint_value as Dictionary
		var checkpoint := CheckpointMarker.new()
		checkpoint.name = String(data.get("id"))
		checkpoint.checkpoint_id = StringName(String(data.get("id")))
		checkpoint.position = Vector2(float(data.get("x")), float(data.get("y")))
		checkpoint.respawn_position = Vector2(float(data.get("respawn_x", data.get("x"))), float(data.get("respawn_y", data.get("y"))))
		checkpoint.collision_layer = 0
		checkpoint.collision_mask = 2
		checkpoint.activated.connect(activate_checkpoint)
		container.add_child(checkpoint)


func _build_exit(spec: LevelSpec, parent: Node2D) -> void:
	var data := spec.data.get("exit") as Dictionary
	var marker := LevelExitMarker.new()
	marker.name = "Exit"
	marker.position = Vector2(float(data.get("x")), float(data.get("y")))
	marker.collision_layer = 0
	marker.collision_mask = 2
	marker.telemetry = telemetry
	var sections := spec.data.get("sections") as Array
	if not sections.is_empty():
		marker.section_id = StringName(String((sections[-1] as Dictionary).get("id")))
	parent.add_child(marker)
	marker.completed.connect(_on_level_completed)


func _build_rule_label(spec: LevelSpec, parent: Node2D) -> void:
	var ids := spec.data.get("ideology_rule_ids") as Array
	if ids.is_empty():
		return
	var definition := registry.get_definition(ContentRegistry.Kind.IDEOLOGY_RULE, StringName(String(ids[0]))) as IdeologyRuleDefinition
	var label := Label.new()
	label.name = "ActiveRule"
	label.position = Vector2(18.0, 180.0)
	label.text = "RULE %s\n%s\nCounterplay: %s" % [
		definition.content_id,
		definition.parameters.get("gate_label", definition.display_name),
		", ".join(definition.counterplay_tags),
	]
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)


func _connect_telemetry(player: PlayerController, generated: Node2D) -> void:
	var health := player.get_node("Health") as HealthComponent
	var previous_health := [health.current_health]
	health.health_changed.connect(func(current: float, _maximum: float) -> void:
		if current < previous_health[0]:
			var damage_amount: float = previous_health[0] - current
			telemetry.record_event(&"damage_received", {"amount": damage_amount, "position": _vector_payload(player.global_position)})
			player.add_camera_shake(minf(2.0 + damage_amount * 0.3, 8.0))
		previous_health[0] = current
	)
	health.depleted.connect(func() -> void:
		telemetry.record_event(&"defeat", {"cause": "health", "position": _vector_payload(player.global_position)})
		_retry_to_checkpoint()
	)
	var response := player.get_node_or_null("ContractorDefensiveResponse") as ContractorDefensiveResponse
	for node: Node in generated.find_children("*", "", true, false):
		if node is EffectReceiverComponent:
			var receiver := node as EffectReceiverComponent
			receiver.effect_blocked.connect(func(permission: TargetPermission) -> void:
				telemetry.record_invalid_target(receiver.identity.stable_id, permission)
				if _hud != null:
					_hud.show_feedback("NOT AN AGGRESSOR · %s" % permission.decision_name(), 2.0, "[Aviso: el objetivo aún no es un agresor]")
				if _audio != null:
					_audio.play_cue(FeedbackTone.Cue.NOTICE)
			)
		elif node is ConflictStateComponent:
			var conflict := node as ConflictStateComponent
			conflict.state_changed.connect(func(
				_previous: ConflictStateComponent.State,
				current: ConflictStateComponent.State,
				_reason: ConflictStateComponent.AggressorReason
			) -> void:
				if current == ConflictStateComponent.State.AGGRESSOR and response != null:
					response.activate(_reason)
					if _hud != null:
						_hud.show_feedback("DEFENSIVE RESPONSE · %s" % ConflictStateComponent.AggressorReason.keys()[_reason], 2.0, "[Alerta: agresión confirmada; respuesta defensiva activa]")
					if _audio != null:
						_audio.play_cue(FeedbackTone.Cue.AGGRESSION)
			)
		elif node is CombatTarget:
			var actor := node as CombatTarget
			if actor.is_boss:
				actor.boss_phase_changed.connect(func(_target_id: StringName, phase: int) -> void:
					if _hud != null:
						_hud.show_feedback("COMMANDER ADAPTS · PHASE %d" % phase, 2.5, "[Alerta grave: el Commander cambia su patrón]")
					if _audio != null:
						_audio.play_cue(FeedbackTone.Cue.BOSS_PHASE)
				)


func _build_debug_hud(spec: LevelSpec, player: PlayerController, parent: Node2D) -> void:
	var profile := load(String(spec.data.get("movement_profile_path"))) as PlayerMovementProfile
	_hud = GeneratedLevelHud.new()
	_hud.name = "Hud"
	var slice_data := spec.data.get("slice", {}) as Dictionary
	var rule_ids := spec.data.get("ideology_rule_ids") as Array
	var rule_text := ""
	if not rule_ids.is_empty():
		var rule := registry.get_definition(ContentRegistry.Kind.IDEOLOGY_RULE, StringName(String(rule_ids[0]))) as IdeologyRuleDefinition
		rule_text = String(rule.parameters.get("gate_label", rule.display_name))
	_hud.configure(spec, telemetry, player, profile, String(slice_data.get("objective", "Reach EXIT")), rule_text)
	parent.add_child(_hud)
	_hud.apply_accessibility(_accessibility)


func _build_slice_flow(spec: LevelSpec, parent: Node2D) -> void:
	var slice_data := spec.data.get("slice", {}) as Dictionary
	if slice_data.is_empty():
		return
	_flow = SliceFlowController.new()
	_flow.name = "Flow"
	_flow.configure(
		self,
		String(slice_data.get("title", spec.data.get("display_name", spec.level_id()))),
		String(slice_data.get("intro", "")),
		String(slice_data.get("completion", "")),
		start_in_menu and not _skip_start_menu_once,
		_accessibility
	)
	_flow.accessibility_changed.connect(_apply_accessibility)
	_skip_start_menu_once = false
	parent.add_child(_flow)


func _capture_checkpoint(checkpoint_id: StringName, position: Vector2) -> void:
	if _player == null:
		return
	var actor_states: Dictionary = {}
	for node: Node in find_children("*", "", true, false):
		if node is CombatTarget:
			var actor := node as CombatTarget
			actor_states[String(actor.stable_id)] = actor.capture_runtime_state()
	var rule_state: Dictionary = {}
	for node: Node in find_children("*", "", true, false):
		if node is AccessGate:
			var gate := node as AccessGate
			rule_state[String(gate.gate_id)] = gate.is_open()
		elif node is RuleStateObject:
			var rule_object := node as RuleStateObject
			rule_state[String(rule_object.object_id)] = rule_object.capture_runtime_state()
		elif node is EncounterRuntimeObserver:
			var observer := node as EncounterRuntimeObserver
			rule_state["encounter:%s" % String(observer.encounter_id)] = observer.capture_runtime_state()
	var health := _player.get_node("Health") as HealthComponent
	_checkpoint.capture(checkpoint_id, position, health.maximum_health, actor_states, _collected_reward_ids, rule_state)
	LocalSaveStore.save(loaded_spec.level_id(), _checkpoint)
	telemetry.record_event(&"checkpoint_used", {"checkpoint_id": String(checkpoint_id)})
	if _hud != null and checkpoint_id != &"level_start":
		_hud.show_feedback("CHECKPOINT SAVED", 2.0, "[Tono ascendente: checkpoint guardado]")
		if _audio != null:
			_audio.play_cue(FeedbackTone.Cue.CHECKPOINT)


func _retry_to_checkpoint() -> void:
	if _player == null:
		return
	telemetry.record_event(&"retry", {"checkpoint_id": String(_checkpoint.checkpoint_id)})
	_player.reset_at(_checkpoint.player_position)
	(_player.get_node("Health") as HealthComponent).restore(_checkpoint.health)
	var response := _player.get_node_or_null("ContractorDefensiveResponse") as ContractorDefensiveResponse
	if response != null:
		response.reset()
	for node: Node in find_children("*", "", true, false):
		if node is CombatTarget:
			var actor := node as CombatTarget
			if _checkpoint.actor_states.has(String(actor.stable_id)):
				actor.restore_runtime_state(_checkpoint.actor_states[String(actor.stable_id)] as Dictionary)
		if node is DebugPickup:
			var pickup := node as DebugPickup
			pickup.restore_collected(pickup.pickup_id in _checkpoint.collected_reward_ids)
		elif node is AccessGate:
			var gate := node as AccessGate
			gate.restore_open(bool(_checkpoint.world_rule_state.get(String(gate.gate_id), false)))
		elif node is RuleStateObject:
			var rule_object := node as RuleStateObject
			var saved_state: Variant = _checkpoint.world_rule_state.get(String(rule_object.object_id), {})
			if saved_state is Dictionary:
				rule_object.restore_runtime_state(saved_state as Dictionary)
		elif node is EncounterRuntimeObserver:
			var observer := node as EncounterRuntimeObserver
			var saved_observer_state: Variant = _checkpoint.world_rule_state.get("encounter:%s" % String(observer.encounter_id), {})
			if saved_observer_state is Dictionary:
				observer.restore_runtime_state(saved_observer_state as Dictionary)


func _on_pickup_collected(pickup_id: StringName) -> void:
	if pickup_id not in _collected_reward_ids:
		_collected_reward_ids.append(pickup_id)
	if _hud != null:
		_hud.show_feedback("PERMITTED SUPPLY COLLECTED", 1.5)


func _on_gate_opened(gate_id: StringName) -> void:
	telemetry.record_event(&"route_taken", {"route_tags": ["contractor_access"], "gate_id": String(gate_id)})
	if _hud != null:
		_hud.show_feedback("CONTRACT ACCEPTED · ACCESS GRANTED", 2.0, "[Confirmación: acceso concedido]")


func _on_rule_state_changed(
	rule_id: StringName,
	object_id: StringName,
	previous_state: StringName,
	current_state: StringName,
	interaction_tag: StringName
) -> void:
	telemetry.record_event(&"rule_state_changed", {
		"rule_id": String(rule_id),
		"object_id": String(object_id),
		"from_state": String(previous_state),
		"to_state": String(current_state),
		"interaction_tag": String(interaction_tag),
	})
	if _hud != null:
		_hud.show_feedback(
			"MACHINE OCCUPIED · PLATFORM ACTIVE",
			2.0,
			"[Confirmación: la máquina ahora está ocupada y la plataforma está activa]"
		)


func _on_encounter_resolved(encounter_id: StringName, resolution: StringName) -> void:
	telemetry.record_event(&"encounter_resolved", {
		"encounter_id": String(encounter_id),
		"resolution": String(resolution),
	})
	if _hud != null:
		_hud.show_feedback("ENCOUNTER RESOLVED · %s" % String(resolution).to_upper(), 2.0)


func _on_level_completed() -> void:
	LocalSaveStore.save(loaded_spec.level_id(), _checkpoint)
	slice_completed.emit()
	if _audio != null:
		_audio.play_cue(FeedbackTone.Cue.SUCCESS)
	if _flow != null:
		_flow.append_completion_summary(TelemetryBalanceSummary.completion_line(telemetry.snapshot()))
		_flow.show_completion()


func _apply_accessibility(settings: AccessibilitySettings) -> void:
	_accessibility = settings
	if _player != null:
		_player.player_camera.shake_enabled = settings.screen_shake_enabled
		if not settings.screen_shake_enabled:
			_player.player_camera.offset = Vector2.ZERO
	if _hud != null:
		_hud.apply_accessibility(settings)


func _rule_color(spec: LevelSpec) -> Color:
	var ids := spec.data.get("ideology_rule_ids") as Array
	if ids.is_empty():
		return Color("101527")
	var definition := registry.get_definition(ContentRegistry.Kind.IDEOLOGY_RULE, StringName(String(ids[0]))) as IdeologyRuleDefinition
	return Color(String(definition.parameters.get("primary_color", "101527")))


func _show_errors(result: LevelValidationResult) -> void:
	var label := Label.new()
	label.name = "ValidationErrors"
	label.position = Vector2(20.0, 20.0)
	label.text = "LEVELSPEC INVALID\n" + "\n".join(result.formatted_errors())
	label.modulate = Color("ff7a75")
	add_child(label)
	for error: String in result.formatted_errors():
		push_error(error)


func _clear_generated() -> void:
	_player = null
	telemetry = null
	loaded_spec = null
	_hud = null
	_flow = null
	_audio = null
	_collected_reward_ids.clear()
	_encounter_actors.clear()
	_checkpoint = RunCheckpointState.new()
	_fall_reset_y = INF
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


func _vector_payload(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.1), "y": snappedf(value.y, 0.1)}
