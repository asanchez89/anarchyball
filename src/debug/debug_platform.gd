class_name DebugPlatform
extends StaticBody2D

@export var size: Vector2 = Vector2(320.0, 48.0)
@export var fill_color: Color = Color("28314f")
@export var edge_color: Color = Color("76e6ff")

var _rule_enabled: bool = true
var _collision_shape: CollisionShape2D


func _ready() -> void:
	_collision_shape = CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	_collision_shape.shape = rectangle_shape
	add_child(_collision_shape)
	_apply_rule_enabled()
	queue_redraw()


func _draw() -> void:
	var rectangle := Rect2(-size * 0.5, size)
	var alpha := 1.0 if _rule_enabled else 0.22
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
