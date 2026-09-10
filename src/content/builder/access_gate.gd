class_name AccessGate
extends StaticBody2D

signal opened(gate_id: StringName)

var gate_id: StringName = &"access_gate"
var required_tag: StringName = &""
var player_tags: Array[StringName] = []
var size: Vector2 = Vector2(42.0, 150.0)
var rule_text: String = "Acceso contractual"
var _player_nearby: bool = false
var _is_open: bool = false
var _shape_node: CollisionShape2D
var _label: Label


func _ready() -> void:
	_shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	_shape_node.shape = shape
	add_child(_shape_node)
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var sensor_shape_node := CollisionShape2D.new()
	var sensor_shape := RectangleShape2D.new()
	sensor_shape.size = Vector2(size.x + 120.0, size.y + 30.0)
	sensor_shape_node.shape = sensor_shape
	sensor.add_child(sensor_shape_node)
	sensor.body_entered.connect(func(body: Node2D) -> void:
		if body is PlayerController:
			_player_nearby = true
			_update_label()
	)
	sensor.body_exited.connect(func(body: Node2D) -> void:
		if body is PlayerController:
			_player_nearby = false
			_update_label()
	)
	add_child(sensor)
	_label = Label.new()
	_label.position = Vector2(-100.0, -size.y * 0.5 - 58.0)
	_label.size = Vector2(200.0, 50.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)
	_update_label()
	queue_redraw()


func _process(_delta: float) -> void:
	if _player_nearby and not _is_open and required_tag in player_tags and InputActions.is_interact_just_pressed():
		_is_open = true
		_shape_node.set_deferred("disabled", true)
		opened.emit(gate_id)
		_update_label()
		queue_redraw()


func _draw() -> void:
	var color := Color("8fe38855") if _is_open else Color("f4b942aa")
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_rect(Rect2(-size * 0.5, size), Color("f4b942"), false, 3.0)
	for y: float in range(int(-size.y * 0.5 + 12.0), int(size.y * 0.5), 24):
		draw_line(Vector2(-size.x * 0.5, y), Vector2(size.x * 0.5, y), Color("171b2b"), 2.0)


func is_open() -> bool:
	return _is_open


func restore_open(value: bool) -> void:
	_is_open = value
	if _shape_node != null:
		_shape_node.disabled = value
	_update_label()
	queue_redraw()


func _update_label() -> void:
	if _label == null:
		return
	if _is_open:
		_label.text = "CONTRATO VERIFICADO · PASO ABIERTO"
	elif required_tag in player_tags:
		_label.text = "%s\nF / X: presentar contrato" % rule_text
	else:
		_label.text = "%s\nBusca el bypass superior" % rule_text
