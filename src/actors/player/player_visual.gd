class_name PlayerVisual
extends Node2D

@export var body_radius: float = 23.0
@export var body_color: Color = Color("f4b942")
@export var outline_color: Color = Color("171b2b")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, body_radius + 3.0, outline_color)
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_circle(Vector2(8.0, -6.0), 4.0, Color.WHITE)
	draw_circle(Vector2(9.5, -6.0), 2.0, outline_color)
	draw_line(Vector2(7.0, 8.0), Vector2(17.0, 5.0), outline_color, 2.5, true)
	draw_line(Vector2(-15.0, -15.0), Vector2(8.0, -22.0), outline_color, 4.0, true)


func update_motion(horizontal_velocity: float, facing_direction: float) -> void:
	var target_rotation: float = clampf(horizontal_velocity / 1800.0, -0.12, 0.12)
	rotation = lerpf(rotation, target_rotation, 0.2)
	if not is_zero_approx(facing_direction):
		scale.x = signf(facing_direction)
