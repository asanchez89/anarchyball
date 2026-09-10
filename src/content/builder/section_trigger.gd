class_name SectionTrigger
extends Area2D

var section_id: StringName = &""
var size: Vector2 = Vector2.ONE
var telemetry: LocalRunTelemetry
var _entered: bool = false
var _completed: bool = false


func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if _entered or not body is PlayerController or telemetry == null:
		return
	_entered = true
	telemetry.record_event(&"section_entered", {"section_id": String(section_id)})


func _on_body_exited(body: Node2D) -> void:
	if _completed or not _entered or not body is PlayerController or telemetry == null:
		return
	_completed = true
	telemetry.record_event(&"section_completed", {"section_id": String(section_id)})
