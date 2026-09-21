class_name CombatTarget
extends Area2D

signal aggression_committed(target_id: StringName, reason: ConflictStateComponent.AggressorReason)
signal neutralized(target_id: StringName)
signal boss_phase_changed(target_id: StringName, phase: int)

enum Behavior {
	STATIC,
	ATTACK_PLAYER,
	ATTACK_THIRD_PARTY,
}

@export var stable_id: StringName = &"combat_target"
@export var display_name: String = "Target"
@export var initial_state: ConflictStateComponent.State = ConflictStateComponent.State.NEUTRAL
@export var target_kind: EffectReceiverComponent.TargetKind = EffectReceiverComponent.TargetKind.BALL
@export var machine_permission: EffectReceiverComponent.DamagePermission = EffectReceiverComponent.DamagePermission.OWNED_NEUTRAL
@export var behavior: Behavior = Behavior.STATIC
@export var aggressor_reason: ConflictStateComponent.AggressorReason = ConflictStateComponent.AggressorReason.NONE
@export_multiline var threat_text: String = ""
@export var protected_target_id: StringName = &"protected_merchant"
@export var protected_target_path: NodePath
@export var duel_enabled: bool = false
@export_range(0.1, 10.0, 0.1) var telegraph_delay: float = 1.5
@export_range(0.0, 3.0, 0.05) var commitment_impact_delay: float = 0.35
@export_range(1.0, 1000.0, 1.0) var maximum_resolve: float = 30.0
@export var hostile_bolt_scene: PackedScene
@export var player_path: NodePath
@export var is_boss: bool = false
@export_range(0.1, 0.9, 0.05) var phase_two_ratio: float = 0.5
@export_range(0.2, 5.0, 0.1) var attack_interval: float = 1.2
@export_range(50.0, 2000.0, 10.0) var activation_distance: float = 520.0
@export_range(0.0, 500.0, 1.0) var patrol_distance: float = 0.0
@export_range(0.0, 300.0, 1.0) var patrol_speed: float = 0.0
@export_range(0.05, 1.0, 0.05) var attack_visual_duration: float = 0.3
@export_range(0.0, 0.95, 0.05) var surrender_resolve_ratio: float = 0.0
@export var defeat_response: EnemyArchetype.DefeatResponse = EnemyArchetype.DefeatResponse.SURRENDER
@export var sustained_attack: bool = false

@onready var identity: CombatIdentityComponent = %Identity
@onready var conflict_state: ConflictStateComponent = %ConflictState
@onready var resolve: ResolveComponent = %Resolve
@onready var receiver: EffectReceiverComponent = %EffectReceiver
@onready var duel_context: VoluntaryDuelContext = %DuelContext
@onready var status_label: Label = %StatusLabel
@onready var sfx: GameplaySfxEmitter = %Sfx

var _last_decision: String = "SIN INTENTOS"
var _machine_disabled: bool = false
var _attack_line_remaining: float = 0.0
var _attack_line_target: Vector2 = Vector2.ZERO
var _behavior_elapsed: float = 0.0
var _telegraph_started: bool = false
var _aggression_committed: bool = false
var _surrender_remaining: float = 0.0
var _boss_phase: int = 1
var _attack_cooldown: float = 0.0
var _third_party_impact_remaining: float = -1.0
var _attack_visual_remaining: float = 0.0
var _ball_visual: BallVisual
var _dialogue_lines: Array[String] = []
var _dialogue_auto_start: bool = true
var _dialogue_player: PlayerController
var _patrol_origin_x: float = 0.0
var _patrol_direction: float = 1.0
var _status_icon: ConflictStatusIcon
var _is_patrolling: bool = false


func apply_archetype(archetype: EnemyArchetype) -> void:
	stable_id = archetype.content_id
	display_name = archetype.display_name
	initial_state = archetype.initial_conflict_state
	target_kind = archetype.target_kind
	machine_permission = archetype.machine_permission
	maximum_resolve = archetype.maximum_resolve
	surrender_resolve_ratio = archetype.surrender_resolve_ratio
	defeat_response = archetype.defeat_response
	is_boss = archetype.is_boss
	phase_two_ratio = archetype.phase_two_ratio
	attack_interval = archetype.attack_interval
	sustained_attack = archetype.sustained_attack
	activation_distance = archetype.activation_distance
	patrol_distance = archetype.patrol_distance
	patrol_speed = archetype.patrol_speed
	telegraph_delay = archetype.telegraph_delay
	commitment_impact_delay = archetype.commitment_impact_delay
	aggressor_reason = archetype.aggressor_reason
	threat_text = archetype.threat_text
	_dialogue_lines = archetype.dialogue_lines.duplicate()
	_dialogue_auto_start = archetype.dialogue_auto_start
	if archetype.visual_definition != null:
		_ball_visual = BallVisual.new()
		_ball_visual.name = "BallVisual"
		_ball_visual.definition = archetype.visual_definition
		add_child(_ball_visual)
	match archetype.behavior_id:
		&"attack_player":
			behavior = Behavior.ATTACK_PLAYER
		&"attack_third_party":
			behavior = Behavior.ATTACK_THIRD_PARTY
		_:
			behavior = Behavior.STATIC


func _ready() -> void:
	_patrol_origin_x = position.x
	_status_icon = ConflictStatusIcon.new()
	_status_icon.name = "ConflictStatusIcon"
	_status_icon.position = Vector2(0.0, -68.0)
	_status_icon.z_index = 30
	add_child(_status_icon)
	identity.stable_id = stable_id
	identity.authority = CombatIdentityComponent.Authority.MACHINE if target_kind == EffectReceiverComponent.TargetKind.MACHINE else CombatIdentityComponent.Authority.NPC
	conflict_state.reset_conflict(initial_state)
	resolve.maximum_resolve = maximum_resolve
	resolve.surrender_threshold = maximum_resolve * surrender_resolve_ratio
	resolve.reset()
	receiver.target_kind = target_kind
	receiver.machine_permission = machine_permission
	duel_context.duel_id = &"training_duel"
	duel_context.participant_ids = [&"player", stable_id]
	duel_context.active = duel_enabled
	conflict_state.state_changed.connect(_on_state_changed)
	resolve.resolve_changed.connect(_on_resolve_changed)
	resolve.surrender_threshold_reached.connect(_on_surrender_threshold_reached)
	receiver.effect_applied.connect(_on_effect_applied)
	receiver.effect_blocked.connect(_on_effect_blocked)
	_update_presentation()
	_build_dialogue()


func _build_dialogue() -> void:
	if _dialogue_lines.is_empty():
		return
	var dialogue := NpcDialogueBubble.new()
	dialogue.name = "NpcDialogue"
	dialogue.configure(display_name.get_slice(" · ", 0), _dialogue_lines, _dialogue_auto_start)
	dialogue.player_proximity_changed.connect(_on_dialogue_player_proximity_changed)
	add_child(dialogue)


func _process(delta: float) -> void:
	_face_dialogue_player()
	_update_patrol(delta)
	_attack_line_remaining = maxf(_attack_line_remaining - delta, 0.0)
	if _attack_visual_remaining > 0.0:
		_attack_visual_remaining = maxf(_attack_visual_remaining - delta, 0.0)
		if is_zero_approx(_attack_visual_remaining):
			_update_ball_visual_state()
	_update_pending_third_party_impact(delta)
	_update_behavior(delta)
	if _surrender_remaining > 0.0:
		_surrender_remaining = maxf(_surrender_remaining - delta, 0.0)
		if is_zero_approx(_surrender_remaining):
			conflict_state.neutralize()
	queue_redraw()


func _update_patrol(delta: float) -> void:
	if behavior == Behavior.STATIC or patrol_distance <= 0.0 or patrol_speed <= 0.0:
		_set_patrolling(false)
		return
	if _telegraph_started or _aggression_committed or conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
		_set_patrolling(false)
		return
	_set_patrolling(true)
	var next_x := position.x + _patrol_direction * patrol_speed * delta
	var left_edge := _patrol_origin_x - patrol_distance
	var right_edge := _patrol_origin_x + patrol_distance
	if next_x <= left_edge or next_x >= right_edge:
		_patrol_direction *= -1.0
		next_x = clampf(next_x, left_edge, right_edge)
	position.x = next_x
	if _ball_visual != null:
		_ball_visual.set_facing(_patrol_direction)


func _set_patrolling(value: bool) -> void:
	if _is_patrolling == value:
		return
	_is_patrolling = value
	_update_ball_visual_state()


func _on_dialogue_player_proximity_changed(player: PlayerController, nearby: bool) -> void:
	_dialogue_player = player if nearby else null


func _face_dialogue_player() -> void:
	if _dialogue_player == null or _ball_visual == null:
		return
	var direction := signf(_dialogue_player.global_position.x - global_position.x)
	if not is_zero_approx(direction):
		_ball_visual.set_facing(direction)


func _draw() -> void:
	var body_color := _state_color()
	if target_kind == EffectReceiverComponent.TargetKind.MACHINE:
		draw_rect(Rect2(-28.0, -36.0, 56.0, 72.0), body_color)
		draw_rect(Rect2(-28.0, -36.0, 56.0, 72.0), Color("171b2b"), false, 4.0)
		draw_circle(Vector2.ZERO, 10.0, Color("171b2b"), false, 3.0)
	else:
		if _ball_visual == null:
			draw_circle(Vector2.ZERO, 28.0, Color("171b2b"))
			draw_circle(Vector2.ZERO, 24.0, body_color)
			draw_circle(Vector2(-8.0, -5.0), 3.0, Color("171b2b"))
			draw_circle(Vector2(8.0, -5.0), 3.0, Color("171b2b"))
	if _attack_line_remaining > 0.0:
		draw_dashed_line(Vector2.ZERO, to_local(_attack_line_target), Color.WHITE, 3.0, 10.0)


func _update_behavior(delta: float) -> void:
	if behavior == Behavior.STATIC:
		return
	var player := get_node_or_null(player_path) as PlayerController
	if player == null or global_position.distance_to(player.global_position) > activation_distance:
		return
	if _aggression_committed:
		if is_boss and conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR:
			_update_boss_pattern(delta)
		elif sustained_attack and conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR:
			_update_sustained_attack(delta)
		return
	_behavior_elapsed += delta
	if not _telegraph_started and _behavior_elapsed >= 0.8:
		_telegraph_started = conflict_state.begin_threatening()
	if not _telegraph_started or _behavior_elapsed < 0.8 + telegraph_delay:
		return
	var committed := false
	if behavior == Behavior.ATTACK_THIRD_PARTY:
		committed = conflict_state.commit_aggression(aggressor_reason, protected_target_id)
		if not committed:
			return
		_third_party_impact_remaining = commitment_impact_delay
	else:
		committed = conflict_state.commit_aggression(aggressor_reason)
		if not committed:
			return
		_launch_hostile_bolt()
		_attack_cooldown = attack_interval
	_aggression_committed = true
	aggression_committed.emit(stable_id, conflict_state.aggressor_reason)


func _update_pending_third_party_impact(delta: float) -> void:
	if _third_party_impact_remaining < 0.0:
		return
	if conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
		_third_party_impact_remaining = -1.0
		return
	_third_party_impact_remaining -= delta
	if _third_party_impact_remaining <= 0.0:
		_third_party_impact_remaining = -1.0
		_attack_protected_target()


func stop_behavior() -> void:
	behavior = Behavior.STATIC
	_behavior_elapsed = 0.0
	_aggression_committed = false
	_third_party_impact_remaining = -1.0
	_attack_visual_remaining = 0.0
	if conflict_state.current_state == ConflictStateComponent.State.THREATENING:
		conflict_state.cancel_threat()
	_telegraph_started = false
	_update_presentation()


func _attack_protected_target() -> void:
	var protected_target := get_node_or_null(protected_target_path) as CombatTarget
	if protected_target == null:
		return
	_attack_line_target = protected_target.global_position
	_attack_line_remaining = 0.45
	_begin_attack_visual()
	protected_target.receiver.receive_effect(
		identity,
		EffectContext.encounter_effect(EffectContext.EffectType.KINETIC_DAMAGE, EffectContext.Origin.DIRECT),
		5.0
	)


func _launch_hostile_bolt() -> void:
	if hostile_bolt_scene == null:
		return
	var player := get_node_or_null(player_path) as PlayerController
	if player == null:
		return
	_launch_bolt_direction(global_position.direction_to(player.global_position))


func _launch_bolt_direction(direction: Vector2) -> void:
	var launch_direction := direction.normalized() if not direction.is_zero_approx() else Vector2.LEFT
	if _ball_visual != null and not is_zero_approx(launch_direction.x):
		_ball_visual.set_facing(signf(launch_direction.x))
	var bolt := hostile_bolt_scene.instantiate() as HostileBolt
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + launch_direction * 34.0
	bolt.configure(launch_direction, identity)
	_begin_attack_visual()


func _begin_attack_visual() -> void:
	_attack_visual_remaining = attack_visual_duration
	_update_ball_visual_state()


func _update_boss_pattern(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_cooldown > 0.0:
		return
	var player := get_node_or_null(player_path) as PlayerController
	if player == null:
		return
	var direction := global_position.direction_to(player.global_position)
	_launch_bolt_direction(direction)
	if _boss_phase >= 2:
		_launch_bolt_direction(direction.rotated(0.22))
		_launch_bolt_direction(direction.rotated(-0.22))
	_attack_line_target = player.global_position
	_attack_line_remaining = 0.25
	_attack_cooldown = attack_interval * (0.58 if _boss_phase >= 2 else 1.0)


func _update_sustained_attack(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_cooldown > 0.0:
		return
	_launch_hostile_bolt()
	_attack_cooldown = attack_interval


func _on_surrender_threshold_reached() -> void:
	if target_kind == EffectReceiverComponent.TargetKind.MACHINE:
		_machine_disabled = true
		receiver.machine_permission = EffectReceiverComponent.DamagePermission.OWNED_NEUTRAL
		conflict_state.reset_conflict(ConflictStateComponent.State.NEUTRALIZED)
	elif duel_context.active:
		duel_context.active = false
		conflict_state.reset_conflict(ConflictStateComponent.State.NEUTRALIZED)
	elif defeat_response == EnemyArchetype.DefeatResponse.RESIST_UNTIL_NEUTRALIZED:
		conflict_state.neutralize()
	elif conflict_state.begin_surrender():
		_surrender_remaining = 0.8
	_update_presentation()


func _on_effect_applied(permission: TargetPermission, _amount: float) -> void:
	_last_decision = permission.decision_name()
	sfx.play_cue(&"impact_allowed")
	_update_presentation()


func _on_effect_blocked(permission: TargetPermission) -> void:
	_last_decision = permission.decision_name()
	sfx.play_cue(&"impact_blocked")
	_update_presentation()


func _on_state_changed(
	_previous_state: ConflictStateComponent.State,
	_new_state: ConflictStateComponent.State,
	_reason: ConflictStateComponent.AggressorReason
) -> void:
	if _new_state != ConflictStateComponent.State.AGGRESSOR:
		_attack_visual_remaining = 0.0
	match _new_state:
		ConflictStateComponent.State.THREATENING:
			sfx.play_cue(&"threat")
		ConflictStateComponent.State.AGGRESSOR:
			sfx.play_cue(&"aggression")
		ConflictStateComponent.State.SURRENDERING:
			sfx.play_cue(&"surrender")
	if _new_state == ConflictStateComponent.State.NEUTRALIZED:
		neutralized.emit(stable_id)
	_update_presentation()


func _on_resolve_changed(_current: float, _maximum: float) -> void:
	if is_boss and _boss_phase == 1 and _maximum > 0.0 and _current / _maximum <= phase_two_ratio and _current > 0.0:
		_boss_phase = 2
		boss_phase_changed.emit(stable_id, _boss_phase)
	_update_presentation()


func _update_presentation() -> void:
	if not is_node_ready():
		return
	var state_text := "DISABLED" if _machine_disabled else conflict_state.state_name()
	var state_symbol := _state_symbol()
	var boss_text := " · PHASE %d" % _boss_phase if is_boss else ""
	var active_threat_text := "\n%s" % threat_text if conflict_state.current_state == ConflictStateComponent.State.THREATENING and not threat_text.is_empty() else ""
	var non_hostile_text := ""
	if conflict_state.current_state == ConflictStateComponent.State.NEUTRAL:
		non_hostile_text = "\nNON-HOSTILE · DO NOT ATTACK"
	elif conflict_state.current_state == ConflictStateComponent.State.DISPUTED:
		non_hostile_text = "\nDISPUTE · USE THE MARKED CONTROL OR BYPASS"
	status_label.text = "%s%s\n%s %s · %s%s%s\nResolve %.0f/%.0f\n%s" % [
		display_name,
		boss_text,
		state_symbol,
		state_text,
		conflict_state.reason_name(),
		active_threat_text,
		non_hostile_text,
		resolve.current_resolve,
		resolve.maximum_resolve,
		_last_decision,
	]
	_update_ball_visual_state()
	if _status_icon != null:
		_status_icon.set_state(conflict_state.current_state)
	queue_redraw()


func _update_ball_visual_state() -> void:
	if _ball_visual == null:
		return
	_ball_visual.set_state(presentation_state_id())


func presentation_state_id() -> StringName:
	if conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR:
		return &"action" if _attack_visual_remaining > 0.0 else &"threatening"
	if _is_patrolling and conflict_state.current_state in [ConflictStateComponent.State.NEUTRAL, ConflictStateComponent.State.DISPUTED]:
		return &"move"
	match conflict_state.current_state:
		ConflictStateComponent.State.THREATENING:
			return &"threatening"
		ConflictStateComponent.State.SURRENDERING:
			return &"surrendering"
		ConflictStateComponent.State.NEUTRALIZED:
			return &"neutralized"
		_:
			return &"idle"


func _state_symbol() -> String:
	if _machine_disabled:
		return "[×]"
	match conflict_state.current_state:
		ConflictStateComponent.State.THREATENING:
			return "[!]"
		ConflictStateComponent.State.AGGRESSOR:
			return "[⚔]"
		ConflictStateComponent.State.SURRENDERING:
			return "[↑↑]"
		ConflictStateComponent.State.NEUTRALIZED:
			return "[✓]"
		ConflictStateComponent.State.DISPUTED:
			return "[?]"
		_:
			return "[○]"


func capture_runtime_state() -> Dictionary:
	return {
		"conflict_state": conflict_state.current_state,
		"aggressor_reason": conflict_state.aggressor_reason,
		"resolve": resolve.current_resolve,
		"aggression_committed": _aggression_committed,
		"telegraph_started": _telegraph_started,
		"boss_phase": _boss_phase,
		"third_party_impact_remaining": _third_party_impact_remaining,
		"position_x": position.x,
		"patrol_origin_x": _patrol_origin_x,
		"patrol_direction": _patrol_direction,
	}


func restore_runtime_state(snapshot: Dictionary) -> void:
	var state: ConflictStateComponent.State = int(snapshot.get("conflict_state", initial_state))
	var reason: ConflictStateComponent.AggressorReason = int(snapshot.get("aggressor_reason", ConflictStateComponent.AggressorReason.NONE))
	conflict_state.reset_conflict(ConflictStateComponent.State.NEUTRAL)
	match state:
		ConflictStateComponent.State.THREATENING:
			conflict_state.begin_threatening()
		ConflictStateComponent.State.AGGRESSOR:
			conflict_state.commit_aggression(reason)
		ConflictStateComponent.State.SURRENDERING:
			conflict_state.commit_aggression(reason)
			conflict_state.begin_surrender()
		ConflictStateComponent.State.NEUTRALIZED:
			conflict_state.reset_conflict(ConflictStateComponent.State.NEUTRALIZED)
		_:
			conflict_state.reset_conflict(state)
	resolve.restore(float(snapshot.get("resolve", maximum_resolve)))
	_aggression_committed = bool(snapshot.get("aggression_committed", false))
	_telegraph_started = bool(snapshot.get("telegraph_started", false))
	_boss_phase = int(snapshot.get("boss_phase", 1))
	_third_party_impact_remaining = float(snapshot.get("third_party_impact_remaining", -1.0))
	position.x = float(snapshot.get("position_x", position.x))
	_patrol_origin_x = float(snapshot.get("patrol_origin_x", _patrol_origin_x))
	_patrol_direction = float(snapshot.get("patrol_direction", 1.0))
	_surrender_remaining = 0.0
	_attack_cooldown = 0.0
	_attack_visual_remaining = 0.0
	_update_presentation()


func _state_color() -> Color:
	if _machine_disabled:
		return Color("687087")
	match conflict_state.current_state:
		ConflictStateComponent.State.DISPUTED:
			return Color("a987d4")
		ConflictStateComponent.State.THREATENING:
			return Color("f4b942")
		ConflictStateComponent.State.AGGRESSOR:
			return Color("e65f65")
		ConflictStateComponent.State.SURRENDERING:
			return Color("8fe388")
		ConflictStateComponent.State.NEUTRALIZED:
			return Color("687087")
		_:
			return Color("76b7d8")
