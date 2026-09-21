class_name BallVisualDefinition
extends Resource

@export var visual_id: StringName
@export var keypose_atlas: Texture2D
@export var animation_atlas: Texture2D
@export var action_equipment: Texture2D
@export var action_equipment_socket := Vector2(-35.0, -10.0)
@export var action_equipment_behind_body: bool = true
@export var cell_size := Vector2i(96, 96)
@export var runtime_scale: float = 1.0
@export_range(-1, 1, 2) var source_facing_direction: int = 1
@export_range(0, 7, 1) var idle_frame: int = 0
@export_range(0, 7, 1) var move_frame: int = 2
@export_range(0, 7, 1) var jump_frame: int = 4
@export_range(0, 7, 1) var action_frame: int = 6
@export_range(0, 7, 1) var hurt_frame: int = 7
@export_range(0, 7, 1) var threatening_frame: int = 3
@export_range(0, 7, 1) var surrendering_frame: int = 6
@export_range(0, 7, 1) var neutralized_frame: int = 7


func frame_for(state_id: StringName) -> int:
	match state_id:
		&"move":
			return move_frame
		&"jump":
			return jump_frame
		&"action":
			return action_frame
		&"hurt":
			return hurt_frame
		&"threatening":
			return threatening_frame
		&"surrendering":
			return surrendering_frame
		&"neutralized":
			return neutralized_frame
		_:
			return idle_frame


func row_for(state_id: StringName) -> int:
	match state_id:
		&"move": return 1
		&"jump": return 2
		&"action": return 3
		&"hurt": return 4
		&"threatening": return 5
		&"surrendering": return 6
		&"neutralized": return 7
		_: return 0


func frame_count_for(_state_id: StringName) -> int:
	# El atlas compartido reserva ocho celdas animadas para cada estado. Ninguna
	# ball debe depender de repetir una sola keypose para aparentar animación.
	return 8


func fps_for(state_id: StringName) -> float:
	match state_id:
		&"move": return 10.0
		&"jump", &"action", &"hurt": return 8.0
		_: return 6.0


func texture() -> Texture2D:
	return animation_atlas if animation_atlas != null else keypose_atlas


func facing_scale_for(direction: float, _state_id: StringName = &"idle") -> float:
	var source_direction := source_facing_direction
	if is_zero_approx(direction):
		return float(source_direction)
	return signf(direction) * float(source_direction)


func is_valid() -> bool:
	return (
		not visual_id.is_empty()
		and texture() != null
		and cell_size == Vector2i(96, 96)
		and runtime_scale > 0.0
		and absi(source_facing_direction) == 1
	)
