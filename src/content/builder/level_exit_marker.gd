class_name LevelExitMarker
extends Area2D

signal completion_requested()

var telemetry: LocalRunTelemetry
var section_id: StringName = &"level_exit"
var _completed: bool = false
var _request_pending: bool = false


func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40.0, 90.0)
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-18.0, -45.0, 36.0, 90.0), Color("8fe38833"))
	draw_rect(Rect2(-18.0, -45.0, 36.0, 90.0), Color("8fe388"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-32.0, -54.0), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, 64.0, 14, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if _completed or _request_pending or not body is PlayerController or telemetry == null:
		return
	_request_pending = true
	completion_requested.emit()


func confirm_completion() -> void:
	_completed = true
	_request_pending = false


func reject_completion() -> void:
	_request_pending = false
