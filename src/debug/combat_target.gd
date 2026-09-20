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

@onready var identity: CombatIdentityComponent = %Identity
@onready var conflict_state: ConflictStateComponent = %ConflictState
@onready var resolve: ResolveComponent = %Resolve
@onready var receiver: EffectReceiverComponent = %EffectReceiver
@onready var duel_context: VoluntaryDuelContext = %DuelContext
@onready var status_label: Label = %StatusLabel

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


func apply_archetype(archetype: EnemyArchetype) -> void:
	stable_id = archetype.content_id
	display_name = archetype.display_name
	initial_state = archetype.initial_conflict_state
	target_kind = archetype.target_kind
	machine_permission = archetype.machine_permission
	maximum_resolve = archetype.maximum_resolve
	is_boss = archetype.is_boss
	phase_two_ratio = archetype.phase_two_ratio
	attack_interval = archetype.attack_interval
	activation_distance = archetype.activation_distance
	telegraph_delay = archetype.telegraph_delay
	commitment_impact_delay = archetype.commitment_impact_delay
	aggressor_reason = archetype.aggressor_reason
	threat_text = archetype.threat_text
	match archetype.behavior_id:
		&"attack_player":
			behavior = Behavior.ATTACK_PLAYER
		&"attack_third_party":
			behavior = Behavior.ATTACK_THIRD_PARTY
		_:
			behavior = Behavior.STATIC


func _ready() -> void:
	identity.stable_id = stable_id
	identity.authority = CombatIdentityComponent.Authority.MACHINE if target_kind == EffectReceiverComponent.TargetKind.MACHINE else CombatIdentityComponent.Authority.NPC
	conflict_state.reset_conflict(initial_state)
	resolve.maximum_resolve = maximum_resolve
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


func _process(delta: float) -> void:
	_attack_line_remaining = maxf(_attack_line_remaining - delta, 0.0)
	_update_pending_third_party_impact(delta)
	_update_behavior(delta)
	if _surrender_remaining > 0.0:
		_surrender_remaining = maxf(_surrender_remaining - delta, 0.0)
		if is_zero_approx(_surrender_remaining):
			conflict_state.neutralize()
	queue_redraw()


func _draw() -> void:
	var body_color := _state_color()
	if target_kind == EffectReceiverComponent.TargetKind.MACHINE:
		draw_rect(Rect2(-28.0, -36.0, 56.0, 72.0), body_color)
		draw_rect(Rect2(-28.0, -36.0, 56.0, 72.0), Color("171b2b"), false, 4.0)
		draw_circle(Vector2.ZERO, 10.0, Color("171b2b"), false, 3.0)
	else:
		draw_circle(Vector2.ZERO, 28.0, Color("171b2b"))
		draw_circle(Vector2.ZERO, 24.0, body_color)
		draw_circle(Vector2(-8.0, -5.0), 3.0, Color("171b2b"))
		draw_circle(Vector2(8.0, -5.0), 3.0, Color("171b2b"))
	if conflict_state.current_state == ConflictStateComponent.State.THREATENING:
		draw_string(ThemeDB.fallback_font, Vector2(-7.0, -42.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color.WHITE)
	if conflict_state.current_state == ConflictStateComponent.State.SURRENDERING:
		draw_line(Vector2(-14.0, -38.0), Vector2(-14.0, -62.0), Color.WHITE, 3.0)
		draw_line(Vector2(14.0, -38.0), Vector2(14.0, -62.0), Color.WHITE, 3.0)
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
	var bolt := hostile_bolt_scene.instantiate() as HostileBolt
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position
	bolt.configure(direction, identity)


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


func _on_surrender_threshold_reached() -> void:
	if target_kind == EffectReceiverComponent.TargetKind.MACHINE:
		_machine_disabled = true
		receiver.machine_permission = EffectReceiverComponent.DamagePermission.OWNED_NEUTRAL
		conflict_state.reset_conflict(ConflictStateComponent.State.NEUTRALIZED)
	elif duel_context.active:
		duel_context.active = false
		conflict_state.reset_conflict(ConflictStateComponent.State.NEUTRALIZED)
	elif conflict_state.begin_surrender():
		_surrender_remaining = 0.8
	_update_presentation()


func _on_effect_applied(permission: TargetPermission, _amount: float) -> void:
	_last_decision = permission.decision_name()
	_update_presentation()


func _on_effect_blocked(permission: TargetPermission) -> void:
	_last_decision = permission.decision_name()
	_update_presentation()


func _on_state_changed(
	_previous_state: ConflictStateComponent.State,
	_new_state: ConflictStateComponent.State,
	_reason: ConflictStateComponent.AggressorReason
) -> void:
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
	status_label.text = "%s%s\n%s %s · %s%s\nResolve %.0f/%.0f\n%s" % [
		display_name,
		boss_text,
		state_symbol,
		state_text,
		conflict_state.reason_name(),
		active_threat_text,
		resolve.current_resolve,
		resolve.maximum_resolve,
		_last_decision,
	]
	queue_redraw()


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
	_surrender_remaining = 0.0
	_attack_cooldown = 0.0
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
