class_name InputActions
extends RefCounted

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const JUMP: StringName = &"jump"
const CROUCH_OR_DROP: StringName = &"crouch_or_drop"
const ATTACK_PRIMARY: StringName = &"attack_primary"
const ATTACK_SECONDARY: StringName = &"attack_secondary"
const AIM_LEFT: StringName = &"aim_left"
const AIM_RIGHT: StringName = &"aim_right"
const AIM_UP: StringName = &"aim_up"
const AIM_DOWN: StringName = &"aim_down"
const ABILITY_1: StringName = &"ability_1"
const ABILITY_2: StringName = &"ability_2"
const INTERACT: StringName = &"interact"
const DODGE_OR_DASH: StringName = &"dodge_or_dash"
const PAUSE: StringName = &"pause"
const PLAYER_MENU: StringName = &"player_menu"

const REQUIRED_ACTIONS: Array[StringName] = [
	MOVE_LEFT,
	MOVE_RIGHT,
	JUMP,
	CROUCH_OR_DROP,
	ATTACK_PRIMARY,
	ATTACK_SECONDARY,
	AIM_LEFT,
	AIM_RIGHT,
	AIM_UP,
	AIM_DOWN,
	ABILITY_1,
	ABILITY_2,
	INTERACT,
	DODGE_OR_DASH,
	PAUSE,
	PLAYER_MENU,
]


static func movement_axis() -> float:
	return Input.get_axis(MOVE_LEFT, MOVE_RIGHT)


static func directional_aim_vector() -> Vector2:
	return Input.get_vector(AIM_LEFT, AIM_RIGHT, AIM_UP, AIM_DOWN)


static func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(JUMP)


static func is_jump_just_released() -> bool:
	return Input.is_action_just_released(JUMP)


static func is_attack_primary_pressed() -> bool:
	return Input.is_action_pressed(ATTACK_PRIMARY)


static func is_ability_1_just_pressed() -> bool:
	return Input.is_action_just_pressed(ABILITY_1)


static func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed(INTERACT)


static func is_pause_just_pressed() -> bool:
	return Input.is_action_just_pressed(PAUSE)


static func pointer_aim_vector(origin: Vector2, pointer_position: Vector2) -> Vector2:
	return origin.direction_to(pointer_position)


static func active_actions() -> PackedStringArray:
	var active := PackedStringArray()
	for action: StringName in REQUIRED_ACTIONS:
		if Input.is_action_pressed(action):
			active.append(String(action))
	return active
