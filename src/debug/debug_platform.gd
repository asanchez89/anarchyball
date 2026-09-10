class_name DebugPlatform
extends StaticBody2D

@export var size: Vector2 = Vector2(320.0, 48.0)
@export var fill_color: Color = Color("28314f")
@export var edge_color: Color = Color("76e6ff")


func _ready() -> void:
	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape
	add_child(collision_shape)
	queue_redraw()


func _draw() -> void:
	var rectangle := Rect2(-size * 0.5, size)
	draw_rect(rectangle, fill_color)
	draw_line(rectangle.position, rectangle.position + Vector2(size.x, 0.0), edge_color, 3.0, true)
