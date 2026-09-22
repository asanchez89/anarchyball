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
@export_range(4, 8, 1) var animation_columns: int = 8
@export var animation_rows: Dictionary = {}
@export var fit_visible_frame_height: float = 0.0
## Cell-local sphere bounds, excluding accessories; optional authored calibration.
@export var frame_body_bounds: Array[Rect2] = []
@export var runtime_body_size := Vector2(76.0, 76.0)
@export var body_ground_y: float = 18.0
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
	if animation_rows.has(String(state_id)):
		return int(animation_rows[String(state_id)])
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
	return animation_columns


func fps_for(state_id: StringName) -> float:
	match state_id:
		&"move": return 10.0
		&"jump", &"action", &"hurt": return 8.0
		_: return 6.0


func texture() -> Texture2D:
	return animation_atlas if animation_atlas != null else keypose_atlas


static func visible_frame_bounds(image: Image) -> Rect2i:
	# Ignore near-transparent export noise when fitting; keep source pixels intact.
	var minimum := image.get_size()
	var maximum := Vector2i(-1, -1)
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a <= 0.01:
				continue
			minimum = minimum.min(Vector2i(x, y))
			maximum = maximum.max(Vector2i(x, y))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE) if maximum.x >= 0 else Rect2i()


func facing_scale_for(direction: float, _state_id: StringName = &"idle") -> float:
	var source_direction := source_facing_direction
	if is_zero_approx(direction):
		return float(source_direction)
	return signf(direction) * float(source_direction)


func is_valid() -> bool:
	if not frame_body_bounds.is_empty():
		if texture() == null or cell_size.y <= 0 or runtime_body_size.x <= 0.0 or runtime_body_size.y <= 0.0:
			return false
		if frame_body_bounds.size() != animation_columns * (texture().get_height() / cell_size.y):
			return false
		for bounds: Rect2 in frame_body_bounds:
			if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or not Rect2(Vector2.ZERO, Vector2(cell_size)).encloses(bounds):
				return false
	if animation_atlas != null:
		if animation_columns < 4 or animation_columns > 8 or animation_atlas.get_width() < cell_size.x * animation_columns:
			return false
		for state: StringName in [&"idle", &"move", &"jump", &"action", &"hurt", &"threatening", &"surrendering", &"neutralized"]:
			if row_for(state) < 0 or (row_for(state) + 1) * cell_size.y > animation_atlas.get_height():
				return false
	return (
		not visual_id.is_empty()
		and texture() != null
		and cell_size.x > 0 and cell_size.y > 0
		and runtime_scale > 0.0
		and absi(source_facing_direction) == 1
	)
