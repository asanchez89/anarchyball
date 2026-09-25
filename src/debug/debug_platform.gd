class_name DebugPlatform
extends AnimatableBody2D

@export var size: Vector2 = Vector2(320.0, 48.0)
@export var fill_color: Color = Color("28314f")
@export var edge_color: Color = Color("76e6ff")
@export var art_backed: bool = false
@export_range(0.0, 64.0, 1.0) var collision_surface_depth: float = 0.0
@export_range(0.0, 3.0, 0.1) var stop_duration: float = 0.8

var _rule_enabled: bool = true
var _collision_shape: CollisionShape2D
var _motion_distance_y: float = 0.0
var _motion_speed: float = 0.0
var _motion_origin_y: float = 0.0
var _motion_direction: float = -1.0
var _moving_art_texture: Texture2D
var _stop_remaining: float = 0.0
var surface_art: Array[CanvasItem] = []
var moving_art_region := Rect2(112.0, 32.0, 32.0, 16.0)


func motion_distance_y() -> float:
	return _motion_distance_y


func allows_projectile_passage(origin: Vector2, destination: Vector2, normal: Vector2) -> bool:
	if _collision_shape == null or not _collision_shape.one_way_collision:
		return false
	var local_origin := to_local(origin)
	var local_destination := to_local(destination)
	if local_destination.y <= local_origin.y:
		return false
	var local_normal := global_transform.basis_xform_inv(normal)
	if local_normal.y < -0.5:
		return true
	# Subsequent small steps can start inside a deck already entered from above.
	var bounds := Rect2(Vector2(-size.x * 0.5, collision_surface_depth - size.y * 0.5), size)
	return normal.is_zero_approx() and bounds.has_point(local_origin)


func motion_speed() -> float:
	return _motion_speed


func _ready() -> void:
	_motion_origin_y = position.y
	_stop_remaining = stop_duration
	sync_to_physics = is_moving_platform()
	_collision_shape = CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	_collision_shape.shape = rectangle_shape
	_collision_shape.position.y = collision_surface_depth
	# Thin ledges are traversable from below. This prevents workshop catwalks
	# from becoming accidental ceilings while preserving their upper route.
	_collision_shape.one_way_collision = size.y <= 32.0
	_collision_shape.one_way_collision_margin = 8.0
	add_child(_collision_shape)
	_build_moving_art()
	_apply_rule_enabled()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _rule_enabled or is_zero_approx(_motion_distance_y) or _motion_speed <= 0.0:
		return
	if _stop_remaining > 0.0:
		_stop_remaining = maxf(0.0, _stop_remaining - delta)
		return
	var destination_y := _motion_origin_y + _motion_distance_y if _motion_direction < 0.0 else _motion_origin_y
	position.y = move_toward(position.y, destination_y, _motion_speed * delta)
	if is_equal_approx(position.y, destination_y):
		_motion_direction *= -1.0
		_stop_remaining = stop_duration


func reset_motion() -> void:
	position.y = _motion_origin_y
	_motion_direction = -1.0
	_stop_remaining = stop_duration


func call_to_nearest_stop(world_y: float) -> void:
	if not is_moving_platform() or not _rule_enabled:
		return
	var origin_world := to_global(Vector2(0.0, _motion_origin_y - position.y)).y
	var other_world := origin_world + _motion_distance_y
	_motion_direction = -1.0 if absf(world_y - other_world) < absf(world_y - origin_world) else 1.0
	_stop_remaining = 0.0


func call_caption(world_y: float) -> String:
	var origin_world := to_global(Vector2(0.0, _motion_origin_y - position.y)).y
	var other_world := origin_world + _motion_distance_y
	var target := other_world if absf(world_y - other_world) < absf(world_y - origin_world) else origin_world
	return "UP" if target < (origin_world + other_world) * 0.5 else "DOWN"


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
		var source_width := minf(32.0, (size.x - index * 96.0) / 3.0)
		atlas.region = Rect2(moving_art_region.position, Vector2(source_width, moving_art_region.size.y))
		var sprite := Sprite2D.new()
		sprite.name = "ElevatorTop%d" % index
		sprite.z_as_relative = false
		sprite.z_index = -8
		sprite.texture = atlas
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(-size.x * 0.5 + index * 96.0, -size.y * 0.5 + collision_surface_depth - 24.0)
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
	for item: CanvasItem in surface_art:
		item.modulate.a = 1.0 if _rule_enabled else 0.22
