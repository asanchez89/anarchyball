class_name CheckpointMarker
extends Area2D

signal activated(checkpoint_id: StringName, respawn_position: Vector2)

var checkpoint_id: StringName = &"checkpoint"
var respawn_position: Vector2 = Vector2.ZERO
var _active: bool = false


func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(54.0, 110.0)
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	var color := Color("8fe388") if _active else Color("76b7d8")
	draw_line(Vector2(0.0, 45.0), Vector2(0.0, -45.0), color, 5.0)
	draw_polygon(PackedVector2Array([Vector2(3.0, -42.0), Vector2(30.0, -30.0), Vector2(3.0, -18.0)]), PackedColorArray([color]))
	draw_string(ThemeDB.fallback_font, Vector2(-48.0, 66.0), "CHECKPOINT", HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if _active or not body is PlayerController:
		return
	_active = true
	queue_redraw()
	activated.emit(checkpoint_id, respawn_position)
