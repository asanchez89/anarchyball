class_name CeasefireChallenge
extends Node

var definition: CeasefireChallengeDefinition
var observer: EncounterRuntimeObserver
var player: PlayerController
var zone := Vector2.ZERO
var remaining: float
var started: bool = false
var dealt_damage: bool = false
var received_damage: bool = false
var stolen: Dictionary = {}
var restoring: bool = false
var _warning: float = 0.0
var _turn_clock: float = 0.0
var _turn: int = 0
var _contacts: Dictionary = {}
var _health_before: float = 100.0
var _restore_epoch: int = 0
var _panel: PanelContainer
var _label: Label
var _bar: ProgressBar
var _homes: Dictionary = {}
var _motors: Dictionary = {}
var _roles: Dictionary = {}
var _goals: Dictionary = {}
var _relieved: Dictionary = {}
var _returning: Dictionary = {}
var _raid_warnings: Dictionary = {}


func configure(owner_observer: EncounterRuntimeObserver, settings: CeasefireChallengeDefinition, actor_player: PlayerController) -> void:
	observer = owner_observer
	definition = settings
	player = actor_player
	remaining = definition.duration
	zone = Vector2(INF, -INF)
	var surfaces: Array[DebugPlatform] = []
	for surface: Node in observer.get_parent().get_parent().get_node("Platforms").get_children():
		if surface is DebugPlatform:
			surfaces.append(surface)
	for actor: CombatTarget in observer._actors:
		actor.externally_managed = true
		zone.x = minf(zone.x, actor.global_position.x - definition.zone_padding)
		zone.y = maxf(zone.y, actor.global_position.x + definition.zone_padding)
		actor.receiver.effect_applied.connect(_on_defensive_effect)
		_homes[actor.stable_id] = actor.global_position
		var motor := BallTacticalMotor.new()
		motor.configure(actor, definition, surfaces)
		actor.add_child(motor)
		_motors[actor.stable_id] = motor
	_health_before = player.health.current_health
	player.health.health_changed.connect(_on_health_changed)


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	_panel = PanelContainer.new()
	_panel.theme = preload("res://assets/ui/game_theme.tres")
	_panel.position = Vector2(660, 125)
	_panel.size = Vector2(585, 125)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_panel)
	var list := VBoxContainer.new()
	_panel.add_child(list)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = 520
	_label.add_theme_font_size_override("font_size", 12)
	list.add_child(_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size.y = 14
	_bar.show_percentage = false
	_bar.max_value = definition.duration
	list.add_child(_bar)
	_update_hud()


func player_in_zone() -> bool:
	return player.global_position.x >= zone.x and player.global_position.x <= zone.y and player.health.current_health > 0.0


func _physics_process(delta: float) -> void:
	advance(delta)
	_update_hud()


func advance(delta: float) -> void:
	if restoring or observer.is_resolved():
		return
	for actor: CombatTarget in observer._actors:
		actor.tactical_moving = false
		actor.external_patrol_enabled = not _roles.has(actor.stable_id) and not _returning.has(actor.stable_id)
	var surrendered := 0
	for actor: CombatTarget in observer._actors:
		if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			surrendered += 1
	if started and (surrendered == observer._actors.size() or (definition.any_surrender_resolves and surrendered > 0)):
		finish(&"force_surrender")
		return
	if definition.mode == CeasefireChallengeDefinition.AttackMode.CONTACT_RAID:
		_advance_raiders(delta)
		return
	if definition.tactical_relay and started:
		_advance_relay(delta)
	if not player_in_zone():
		_warning = 0.0
		for actor: CombatTarget in observer._actors:
			actor.conflict_state.cancel_threat()
		return
	if started:
		remaining = maxf(0.0, remaining - delta)
		if is_zero_approx(remaining):
			finish(&"survive_ceasefire")
			return
	_warning += delta
	for actor: CombatTarget in observer._actors:
		actor.conflict_state.begin_threatening()
	if _warning < definition.warning_seconds:
		return
	if definition.mode == CeasefireChallengeDefinition.AttackMode.ROTATING_FIRE:
		if definition.collective_commitment and observer._actors.any(func(member: CombatTarget) -> bool: return member.global_position.distance_to(player.global_position) <= definition.activation_range):
			for member: CombatTarget in observer._actors:
				if member.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR and _commit(member, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED):
					if member._ball_visual != null:
						member._ball_visual.set_facing(signf(player.global_position.x - member.global_position.x))
					member._begin_attack_visual()
		_turn_clock -= delta
		if _turn_clock <= 0.0:
			var actor := observer._actors[_turn % observer._actors.size()]
			_turn += 1
			_turn_clock = definition.turn_interval
			if not _is_relocating(actor) and actor.global_position.distance_to(player.global_position) <= definition.activation_range and _commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED):
				actor._launch_hostile_bolt()


func _commit(actor: CombatTarget, reason: ConflictStateComponent.AggressorReason) -> bool:
	if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
		return false
	if actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
		if not actor.conflict_state.commit_aggression(reason):
			return false
		actor.aggression_committed.emit(actor.stable_id, reason)
	started = true
	return true


func _chase(actor: CombatTarget, delta: float) -> void:
	var direction := signf(player.global_position.x - actor.global_position.x)
	if actor._ball_visual != null:
		actor._ball_visual.set_facing(direction)
	if actor.global_position.distance_to(player.global_position) <= definition.contact_radius - 2.0:
		return
	var next_x := clampf(actor.global_position.x + direction * definition.chase_speed * delta, zone.x, zone.y)
	for other: CombatTarget in observer._actors:
		if other == actor or other.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			continue
		if absf(player.global_position.y - actor.global_position.y) < 40.0 and absf(other.global_position.y - actor.global_position.y) < 40.0 and absf(other.global_position.x - next_x) < definition.personal_space and absf(other.global_position.x - next_x) < absf(other.global_position.x - actor.global_position.x):
			return
	var home: Vector2 = _homes[actor.stable_id]
	var bounds := Vector2(maxf(zone.x, home.x - definition.pursuit_radius), minf(zone.y, home.x + definition.pursuit_radius))
	(_motors[actor.stable_id] as BallTacticalMotor).travel(player.global_position, definition.chase_speed, bounds, delta)


func _is_relocating(actor: CombatTarget) -> bool:
	return actor.tactical_airborne or String(_roles.get(actor.stable_id, "")) in ["retreat", "relief"]


func _advance_relay(delta: float) -> void:
	for wounded: CombatTarget in observer._actors:
		if _relieved.has(wounded.stable_id) or _is_relocating(wounded) or wounded.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
			continue
		if wounded.resolve.current_resolve > wounded.resolve.maximum_resolve * definition.retreat_resolve_ratio:
			continue
		var replacement: CombatTarget = null
		for candidate: CombatTarget in observer._actors:
			if candidate == wounded or _roles.has(candidate.stable_id) or candidate.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
				continue
			if candidate.resolve.current_resolve <= wounded.resolve.current_resolve:
				continue
			if replacement != null and candidate.resolve.current_resolve <= replacement.resolve.current_resolve:
				if candidate.resolve.current_resolve < replacement.resolve.current_resolve or candidate.global_position.distance_squared_to(wounded.global_position) >= replacement.global_position.distance_squared_to(wounded.global_position):
					continue
			if (_motors[wounded.stable_id] as BallTacticalMotor).route_to(candidate.global_position, zone).is_empty() or (_motors[candidate.stable_id] as BallTacticalMotor).route_to(wounded.global_position, zone).is_empty():
				continue
			replacement = candidate
		if replacement != null:
			_goals[wounded.stable_id] = replacement.global_position
			_goals[replacement.stable_id] = wounded.global_position
			_roles[wounded.stable_id] = "retreat"
			_roles[replacement.stable_id] = "relief"
			_relieved[wounded.stable_id] = true
			wounded.sfx.play_cue(&"tactical_dash")
	for actor: CombatTarget in observer._actors:
		if not _roles.has(actor.stable_id):
			continue
		actor.external_patrol_enabled = false
		var goal: Vector2 = _goals[actor.stable_id]
		if not actor.tactical_airborne and actor.global_position.distance_to(goal) < definition.home_tolerance:
			if _roles[actor.stable_id] == "retreat":
				_roles[actor.stable_id] = "reserve"
			else:
				_roles.erase(actor.stable_id)
				actor._patrol_origin_x = actor.position.x
			actor._set_patrolling(false)
		elif _roles[actor.stable_id] != "reserve":
			(_motors[actor.stable_id] as BallTacticalMotor).travel(goal, definition.retreat_speed, zone, delta)


func _advance_raiders(delta: float) -> void:
	var engaging := false
	for actor: CombatTarget in observer._actors:
		var id := actor.stable_id
		_contacts[id] = maxf(0.0, float(_contacts.get(id, 0.0)) - delta)
		if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			continue
		var home: Vector2 = _homes[id]
		var in_reach := player_in_zone() and absf(player.global_position.x - home.x) <= definition.pursuit_radius and actor.global_position.distance_to(player.global_position) <= definition.activation_range
		if not in_reach and (actor.conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR or actor.global_position.distance_to(home) > actor.patrol_distance + definition.home_tolerance):
			_returning[id] = true
		if _returning.has(id):
			actor.external_patrol_enabled = false
			_raid_warnings.erase(id)
			if not actor.tactical_airborne and actor.global_position.distance_to(home) <= definition.home_tolerance:
				actor.conflict_state.disengage_at_home()
				actor.conflict_state.cancel_threat()
				actor._set_patrolling(false)
				_returning.erase(id)
			else:
				(_motors[id] as BallTacticalMotor).travel(home, definition.return_speed, zone, delta)
			continue
		if not in_reach:
			_raid_warnings.erase(id)
			actor.conflict_state.cancel_threat()
			continue
		engaging = true
		actor.external_patrol_enabled = false
		actor.conflict_state.begin_threatening()
		_raid_warnings[id] = float(_raid_warnings.get(id, 0.0)) + delta
		if float(_raid_warnings[id]) < definition.warning_seconds:
			continue
		_chase(actor, delta)
		if actor.global_position.distance_to(player.global_position) <= definition.commitment_range and _commit(actor, ConflictStateComponent.AggressorReason.FORCED_CONFISCATION):
			try_contact(actor)
	if started and engaging:
		remaining = maxf(0.0, remaining - delta)
		if is_zero_approx(remaining):
			finish(&"survive_ceasefire")


func try_contact(actor: CombatTarget) -> bool:
	if _returning.has(actor.stable_id):
		return false
	if restoring or observer.is_resolved() or not player_in_zone() or actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR or float(_contacts.get(actor.stable_id, 0.0)) > 0.0 or actor.global_position.distance_to(player.global_position) > definition.contact_radius:
		return false
	var receiver := player.get_node("EffectReceiver") as EffectReceiverComponent
	var epoch := _restore_epoch
	var previous_cue := player.damage_feedback_cue
	player.damage_feedback_cue = &"contact_hit"
	var permission := receiver.receive_effect(actor.identity, EffectContext.encounter_effect(EffectContext.EffectType.KINETIC_DAMAGE, EffectContext.Origin.DIRECT), definition.contact_damage)
	player.damage_feedback_cue = previous_cue
	if not permission.allowed or epoch != _restore_epoch or player.health.current_health <= 0.0:
		return false
	_contacts[actor.stable_id] = definition.contact_cooldown
	var stolen_count: int = 0
	if player.inventory != null:
		for item: String in definition.stolen_items:
			var data: Dictionary = player.inventory.profile.items.get(item, {})
			if data.is_empty() or bool(data.get("protected", false)):
				continue
			var amount := mini(player.inventory.count(item), mini(int(definition.stolen_items[item]), int(definition.theft_limit.get(item, 0)) - int(stolen.get(item, 0))))
			if amount > 0 and player.inventory.spend(item, amount):
				stolen[item] = int(stolen.get(item, 0)) + amount
				stolen_count += amount
	if stolen_count > 0:
		if definition.theft_effect != null:
			var burst := definition.theft_effect.instantiate() as TheftBurst
			player.add_child(burst)
			burst.configure(player.global_position, actor.global_position)
		if actor.sfx != null:
			actor.sfx.play_cue(&"theft")
	return true


func finish(resolution: StringName) -> void:
	if observer.is_resolved() or not started or restoring or resolution not in observer.allowed_resolutions:
		return
	# Currency is immediate; WorldLootDrops releases stolen property on resolution.
	if player.inventory != null:
		var reward := definition.reward_sats
		if resolution == &"survive_ceasefire":
			reward += definition.no_attack_bonus if not dealt_damage else 0
			reward += definition.no_hit_bonus if not received_damage else 0
		player.inventory.grant_once("ceasefire:" + String(observer.encounter_id), {}, reward)
	for actor: CombatTarget in observer._actors:
		actor.stop_behavior()
		actor.tactical_moving = false
		if actor.conflict_state.begin_surrender():
			actor._surrender_remaining = 0.8
		elif actor.conflict_state.current_state == ConflictStateComponent.State.THREATENING:
			actor.conflict_state.cancel_threat()
		for node: Node in actor.get_parent().get_children():
			if node is HostileBolt and (node as HostileBolt).source_identity == actor.identity:
				node.queue_free()
	observer.try_resolve(resolution)


func _on_defensive_effect(_permission: TargetPermission, amount: float) -> void:
	if not restoring and started and not observer.is_resolved() and amount > 0.0:
		dealt_damage = true


func _on_health_changed(current: float, _maximum: float) -> void:
	if not restoring and started and player_in_zone() and current < _health_before:
		received_damage = true
	_health_before = current


func _update_hud() -> void:
	_panel.visible = player_in_zone() and not observer.is_resolved()
	_bar.value = definition.duration - remaining
	var instruction := "Una rendición retira al grupo." if definition.any_surrender_resolves else "Esquiva el robo o haz que se rindan todos."
	_label.text = "%s\n%s\n%s" % [definition.title, "ALTO EL FUEGO EN %.1f s" % remaining if started else "ADVERTENCIA · aún no puedes atacar", instruction]
	if not stolen.is_empty():
		_label.text += "\nAl resolver, recoge el paquete con lo robado."
	if _roles.values().has("retreat"):
		_label.text += "\nRELEVO: una herida se repliega; otra cubre su puesto."


func capture_runtime_state() -> Dictionary:
	var motion: Dictionary = {}
	for id: StringName in _motors:
		motion[id] = (_motors[id] as BallTacticalMotor).capture_runtime_state()
	return {"started": started, "remaining": remaining, "dealt_damage": dealt_damage, "received_damage": received_damage, "stolen": stolen.duplicate(true), "turn": _turn, "turn_clock": _turn_clock, "warning": _warning, "contacts": _contacts.duplicate(true), "roles": _roles.duplicate(), "goals": _goals.duplicate(), "relieved": _relieved.duplicate(), "returning": _returning.duplicate(), "raid_warnings": _raid_warnings.duplicate(), "motion": motion}


func restore_runtime_state(state: Dictionary) -> void:
	_restore_epoch += 1
	started = bool(state.get("started", false))
	remaining = clampf(float(state.get("remaining", definition.duration)), 0.0, definition.duration)
	dealt_damage = bool(state.get("dealt_damage", false))
	received_damage = bool(state.get("received_damage", false))
	stolen = (state.get("stolen", {}) as Dictionary).duplicate(true)
	_turn = int(state.get("turn", 0))
	_turn_clock = float(state.get("turn_clock", 0.0))
	_warning = float(state.get("warning", 0.0))
	_contacts = (state.get("contacts", {}) as Dictionary).duplicate(true)
	_roles = (state.get("roles", {}) as Dictionary).duplicate()
	_goals = (state.get("goals", {}) as Dictionary).duplicate()
	_relieved = (state.get("relieved", {}) as Dictionary).duplicate()
	_returning = (state.get("returning", {}) as Dictionary).duplicate()
	_raid_warnings = (state.get("raid_warnings", {}) as Dictionary).duplicate()
	for id: StringName in _motors:
		(_motors[id] as BallTacticalMotor).restore_runtime_state((state.get("motion", {}) as Dictionary).get(id, {}))
	_health_before = player.health.current_health
