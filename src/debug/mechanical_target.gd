class_name MechanicalTarget
extends Area2D

@export var size: Vector2 = Vector2(64.0, 96.0)

var hit_count: int = 0
var _flash_remaining: float = 0.0


func _ready() -> void:
	add_to_group(&"sandbox_target")
	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape
	add_child(collision_shape)
	queue_redraw()


func _process(delta: float) -> void:
	_flash_remaining = maxf(_flash_remaining - delta, 0.0)
	queue_redraw()


func register_probe_hit() -> void:
	hit_count += 1
	_flash_remaining = 0.12


func _draw() -> void:
	var color := Color.WHITE if _flash_remaining > 0.0 else Color("e66f7a")
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_rect(Rect2(-size * 0.5, size), Color("171b2b"), false, 4.0)
	draw_circle(Vector2.ZERO, 14.0, Color("171b2b"), false, 4.0)
	draw_line(Vector2(-20.0, 0.0), Vector2(20.0, 0.0), Color("171b2b"), 3.0)
	draw_line(Vector2(0.0, -20.0), Vector2(0.0, 20.0), Color("171b2b"), 3.0)
