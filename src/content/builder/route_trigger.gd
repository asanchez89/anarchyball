class_name RouteTrigger
extends Area2D

var route_tags: Array[StringName] = []
var size: Vector2 = Vector2.ONE
var telemetry: LocalRunTelemetry
var _recorded: bool = false


func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _recorded or not body is PlayerController or telemetry == null:
		return
	_recorded = true
	var serialized_tags: Array[String] = []
	for tag: StringName in route_tags:
		serialized_tags.append(String(tag))
	telemetry.record_event(&"route_taken", {"route_tags": serialized_tags})
