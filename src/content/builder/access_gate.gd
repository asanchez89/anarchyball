class_name AccessGate
extends StaticBody2D

signal opened(gate_id: StringName)

const GATE_CLOSED_TEXTURE := preload("res://assets/art/props/access_gate/warped_gate_closed.png")
const GATE_OPENING_TEXTURE := preload("res://assets/art/props/access_gate/warped_gate_opening.png")
const GATE_OPEN_TEXTURE := preload("res://assets/art/props/access_gate/warped_gate_open.png")

var gate_id: StringName = &"access_gate"
var required_tag: StringName = &""
var player_tags: Array[StringName] = []
var size: Vector2 = Vector2(42.0, 150.0)
var barrier_height: float = 720.0
var rule_text: String = "Acceso contractual"
var _player_nearby: bool = false
var _is_open: bool = false
var _shape_node: CollisionShape2D
var _label: Label
var _art_sprite: AnimatedSprite2D


func _ready() -> void:
	_shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var effective_height := maxf(size.y, barrier_height)
	shape.size = Vector2(size.x, effective_height)
	_shape_node.shape = shape
	# The authored position remains at the visible workshop gate. Its collision
	# extends upward so a mandatory encounter cannot be bypassed with a jump.
	_shape_node.position.y = -(effective_height - size.y) * 0.5
	add_child(_shape_node)
	_build_warped_art()
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
	_apply_open_state(false)
	_update_label()


func _process(_delta: float) -> void:
	if _player_nearby and not _is_open and required_tag in player_tags and InputActions.is_interact_just_pressed():
		_set_open(true)
		opened.emit(gate_id)


func is_open() -> bool:
	return _is_open


func restore_open(value: bool) -> void:
	_set_open(value, false)


func is_collision_enabled() -> bool:
	return _shape_node != null and not _shape_node.disabled and collision_layer != 0


func _set_open(value: bool, animate: bool = true) -> void:
	_is_open = value
	_apply_open_state(animate)
	_update_label()


func _apply_open_state(animate: bool) -> void:
	if _shape_node != null:
		_shape_node.set_deferred("disabled", _is_open)
	set_deferred("collision_layer", 0 if _is_open else 1)
	if _art_sprite == null:
		return
	if _is_open:
		_art_sprite.play(&"opening")
		if not animate:
			_art_sprite.pause()
			_art_sprite.frame = 2
	else:
		_art_sprite.play(&"closed")


func _build_warped_art() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"closed")
	frames.set_animation_loop(&"closed", true)
	frames.add_frame(&"closed", GATE_CLOSED_TEXTURE)
	frames.add_animation(&"opening")
	frames.set_animation_loop(&"opening", false)
	frames.set_animation_speed(&"opening", 10.0)
	frames.add_frame(&"opening", GATE_CLOSED_TEXTURE)
	frames.add_frame(&"opening", GATE_OPENING_TEXTURE)
	frames.add_frame(&"opening", GATE_OPEN_TEXTURE)
	_art_sprite = AnimatedSprite2D.new()
	_art_sprite.name = "WarpedGateArt"
	_art_sprite.sprite_frames = frames
	_art_sprite.animation = &"closed"
	_art_sprite.scale = Vector2(3.0, 3.0)
	_art_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art_sprite.z_index = -1
	add_child(_art_sprite)


func _update_label() -> void:
	if _label == null:
		return
	if _is_open:
		_label.text = (
			"DESAFÍO RESUELTO · PASO ABIERTO"
			if required_tag == &"encounter_resolution"
			else "CONTRATO VERIFICADO · PASO ABIERTO"
		)
	elif required_tag in player_tags:
		_label.text = "%s\nF / X: presentar contrato" % rule_text
	elif required_tag == &"encounter_resolution":
		_label.text = "%s\nResuelve el desafío para abrir" % rule_text
	else:
		_label.text = "%s\nBusca el bypass superior" % rule_text
