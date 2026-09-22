class_name PlayerController
extends CharacterBody2D

signal locomotion_state_changed(new_state: LocomotionState)

enum LocomotionState {
	GROUND,
	AIR,
}

@export var movement_profile: PlayerMovementProfile

@onready var visual: PlayerVisual = %Visual
@onready var player_camera: PlayerCamera = %PlayerCamera
@onready var probe_launcher: SandboxProbeLauncher = $ProbeLauncher
@onready var health: HealthComponent = $Health
@onready var sfx: GameplaySfxEmitter = $Sfx

var locomotion_state: LocomotionState = LocomotionState.AIR
var facing_direction: float = 1.0
var _movement_assist := MovementAssistState.new()
var _previous_health: float
var _gameplay_input_suppressed: bool = false
var inventory: RunInventory
var damage_feedback_cue: StringName = &"hurt"


func _ready() -> void:
	assert(movement_profile != null and movement_profile.is_valid(), "PlayerMovementProfile inválido")
	_previous_health = health.current_health
	probe_launcher.probe_fired.connect(_on_probe_fired)
	health.health_changed.connect(_on_health_changed)


func _physics_process(delta: float) -> void:
	_update_input_release_guard()
	var grounded_before_move: bool = is_on_floor()
	_movement_assist.tick(delta)
	if grounded_before_move:
		_movement_assist.refresh_coyote(movement_profile.coyote_time)
	if not _gameplay_input_suppressed and InputActions.is_jump_just_pressed():
		_movement_assist.buffer_jump(movement_profile.jump_buffer_time)

	var movement_axis: float = InputActions.movement_axis()
	if not is_zero_approx(movement_axis):
		facing_direction = signf(movement_axis)
	velocity.x = MovementMath.horizontal_velocity(
		velocity.x,
		movement_axis,
		grounded_before_move,
		movement_profile,
		delta
	)
	if not grounded_before_move:
		velocity.y = MovementMath.vertical_velocity(velocity.y, movement_profile, delta)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	var jumped_before_move := _try_consume_jump(grounded_before_move)
	if InputActions.is_jump_just_released():
		velocity.y = MovementMath.short_hop_velocity(
			velocity.y,
			movement_profile.short_hop_multiplier
		)

	move_and_slide()
	if is_on_floor() and not jumped_before_move:
		_movement_assist.refresh_coyote(movement_profile.coyote_time)
		_try_consume_jump(true)
	_set_locomotion_state(LocomotionState.GROUND if is_on_floor() else LocomotionState.AIR)
	visual.update_motion(velocity.x, velocity.y, not is_on_floor(), facing_direction)


func _on_health_changed(current: float, _maximum: float) -> void:
	if current < _previous_health:
		visual.play_hurt()
		sfx.play_cue(damage_feedback_cue)
	_previous_health = current


func _on_probe_fired() -> void:
	if inventory != null and probe_launcher.last_weapon_index < inventory.profile.weapon_art.size():
		var index := probe_launcher.last_weapon_index
		visual.set_weapon_art(inventory.profile.weapon_art[index], float(inventory.profile.weapons[index].get("art_scale", 1.0)))
	var aim := probe_launcher.aim_direction()
	if not is_zero_approx(aim.x):
		facing_direction = signf(aim.x)
		visual.update_motion(0.0, velocity.y, not is_on_floor(), facing_direction)
	visual.play_action()
	sfx.play_cue(&"fire")


func reset_at(world_position: Vector2) -> void:
	global_position = world_position
	velocity = Vector2.ZERO
	_movement_assist.reset()


func add_camera_shake(strength: float) -> void:
	player_camera.add_shake(strength)


func suppress_gameplay_input_until_released() -> void:
	_gameplay_input_suppressed = true
	_movement_assist.reset()
	probe_launcher.input_enabled = false


func is_gameplay_input_suppressed() -> bool:
	return _gameplay_input_suppressed


func _update_input_release_guard() -> void:
	if not _gameplay_input_suppressed:
		return
	if Input.is_action_pressed(InputActions.JUMP) or Input.is_action_pressed(InputActions.ATTACK_PRIMARY) or Input.is_action_pressed(InputActions.ATTACK_SECONDARY):
		return
	_gameplay_input_suppressed = false
	probe_launcher.input_enabled = true


func get_coyote_remaining() -> float:
	return _movement_assist.coyote_remaining()


func get_jump_buffer_remaining() -> float:
	return _movement_assist.jump_buffer_remaining()


func get_locomotion_state_name() -> String:
	return LocomotionState.keys()[locomotion_state]


func _try_consume_jump(is_grounded: bool) -> bool:
	if not _movement_assist.can_consume_jump(is_grounded):
		return false
	velocity.y = -movement_profile.jump_velocity
	_movement_assist.consume_jump()
	sfx.play_cue(&"jump")
	return true


func _set_locomotion_state(new_state: LocomotionState) -> void:
	if locomotion_state == new_state:
		return
	locomotion_state = new_state
	locomotion_state_changed.emit(new_state)
