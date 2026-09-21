class_name DebugPlatform
extends StaticBody2D

@export var size: Vector2 = Vector2(320.0, 48.0)
@export var fill_color: Color = Color("28314f")
@export var edge_color: Color = Color("76e6ff")
@export var art_backed: bool = false
@export_range(0.0, 64.0, 1.0) var collision_surface_depth: float = 0.0

var _rule_enabled: bool = true
var _collision_shape: CollisionShape2D
var _motion_distance_y: float = 0.0
var _motion_speed: float = 0.0
var _motion_origin_y: float = 0.0
var _motion_direction: float = -1.0
var _moving_art_texture: Texture2D


func _ready() -> void:
	_motion_origin_y = position.y
	_collision_shape = CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	_collision_shape.shape = rectangle_shape
	_collision_shape.position.y = collision_surface_depth
	# Thin ledges are traversable from below. This prevents workshop catwalks
	# from becoming accidental ceilings while preserving their upper route.
	_collision_shape.one_way_collision = size.y <= 32.0
	add_child(_collision_shape)
	_build_moving_art()
	_apply_rule_enabled()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _rule_enabled or is_zero_approx(_motion_distance_y) or _motion_speed <= 0.0:
		return
	var destination_y := _motion_origin_y + _motion_distance_y if _motion_direction < 0.0 else _motion_origin_y
	position.y = move_toward(position.y, destination_y, _motion_speed * delta)
	if is_equal_approx(position.y, destination_y):
		_motion_direction *= -1.0


func configure_motion(distance_y: float, speed: float, art_texture: Texture2D = null) -> void:
	_motion_distance_y = distance_y
	_motion_speed = speed
	_moving_art_texture = art_texture


func is_moving_platform() -> bool:
	return not is_zero_approx(_motion_distance_y) and _motion_speed > 0.0


func _build_moving_art() -> void:
	if not is_moving_platform() or _moving_art_texture == null:
		return
	var tile_count := maxi(1, ceili(size.x / 96.0))
	for index: int in tile_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = _moving_art_texture
		atlas.region = Rect2(112.0, 32.0, 32.0, 16.0)
		var sprite := Sprite2D.new()
		sprite.name = "ElevatorTop%d" % index
		sprite.texture = atlas
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(-size.x * 0.5 + index * 96.0, -size.y * 0.5 - 15.0)
		sprite.scale = Vector2.ONE * 3.0
		add_child(sprite)


func _draw() -> void:
	var rectangle := Rect2(-size * 0.5, size)
	var alpha := 1.0 if _rule_enabled else 0.22
	if not art_backed:
		draw_rect(rectangle, Color(fill_color, alpha))
		draw_line(rectangle.position, rectangle.position + Vector2(size.x, 0.0), Color(edge_color, alpha), 3.0, true)
	if not _rule_enabled:
		draw_dashed_line(rectangle.position, rectangle.end, Color("b6bdcc88"), 2.0, 8.0)


func set_rule_enabled(value: bool) -> void:
	_rule_enabled = value
	_apply_rule_enabled()
	queue_redraw()


func is_rule_enabled() -> bool:
	return _rule_enabled


func _apply_rule_enabled() -> void:
	if _collision_shape != null:
		_collision_shape.disabled = not _rule_enabled
	self_modulate = Color.WHITE if _rule_enabled else Color(1.0, 1.0, 1.0, 0.2)
