class_name DebugPickup
extends Area2D

signal collected(pickup_id: StringName)

var pickup_id: StringName = &""
var ownership: StringName = &"unowned_collectible"
var _collected: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color("8fe388"))
	draw_circle(Vector2.ZERO, 10.0, Color("171b2b"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-55.0, 28.0), String(ownership), HORIZONTAL_ALIGNMENT_CENTER, 110.0, 10, Color.WHITE)


func is_collected() -> bool:
	return _collected


func restore_collected(value: bool) -> void:
	_collected = value
	visible = not value
	monitoring = not value


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is PlayerController:
		return
	_collected = true
	visible = false
	set_deferred("monitoring", false)
	collected.emit(pickup_id)
