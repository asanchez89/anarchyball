class_name NpcDialogueBubble
extends Node2D

signal conversation_started()
signal line_changed(index: int, text: String)
signal conversation_finished()
signal player_proximity_changed(player: PlayerController, nearby: bool)

const BUBBLE_WIDTH: float = 520.0
const BUBBLE_HEIGHT: float = 196.0
const BUBBLE_OFFSET := Vector2(-260.0, -270.0)
const DIALOGUE_FONT := preload("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf")
const BUBBLE_TEXTURE := preload("res://assets/art/ui/dialogue_bubble_16bit.png")
const TYPEWRITER_CHARACTERS_PER_SECOND: float = 110.0

var speaker_name: String = "NPC"
var lines: Array[String] = []
var auto_start: bool = true
var _player_nearby: bool = false
var _finished: bool = false
var _active: bool = false
var _line_index: int = -1
var _typing_elapsed: float = 0.0
var _typing: bool = false
var _panel: Control
var _speaker_label: Label
var _text_label: Label
var _hint_label: Label
var _nearby_player: PlayerController


func configure(name: String, dialogue_lines: Array[String], starts_automatically: bool) -> void:
	speaker_name = name
	lines = dialogue_lines.duplicate()
	auto_start = starts_automatically


func _ready() -> void:
	add_to_group("npc_dialogue_bubbles")
	z_index = 20
	_build_sensor()
	_build_bubble()
	_refresh()


func _process(delta: float) -> void:
	if _panel != null and _player_nearby:
		_panel.visible = not _finished and _is_nearest_speaker()
	_update_typewriter(delta)
	if not _player_nearby or _finished or not _is_nearest_speaker():
		return
	if InputActions.is_interact_just_pressed():
		advance()


func start() -> bool:
	if lines.is_empty() or _finished or _active:
		return false
	_active = true
	_line_index = 0
	_refresh()
	_begin_typewriter()
	conversation_started.emit()
	line_changed.emit(_line_index, lines[_line_index])
	return true


func advance() -> bool:
	if not _active:
		return start()
	if _typing:
		_reveal_current_line()
		return true
	_line_index += 1
	if _line_index >= lines.size():
		_active = false
		_finished = true
		_refresh()
		conversation_finished.emit()
		return false
	_refresh()
	_begin_typewriter()
	line_changed.emit(_line_index, lines[_line_index])
	return true


func current_line() -> String:
	return lines[_line_index] if _active and _line_index >= 0 and _line_index < lines.size() else ""


func is_active() -> bool:
	return _active


func is_finished() -> bool:
	return _finished


func is_typing() -> bool:
	return _typing


func _begin_typewriter() -> void:
	_typing_elapsed = 0.0
	_typing = not current_line().is_empty()
	if _text_label != null:
		_text_label.visible_characters = 0 if _typing else -1


func _update_typewriter(delta: float) -> void:
	if not _typing or _text_label == null:
		return
	_typing_elapsed += delta
	var character_count := current_line().length()
	_text_label.visible_characters = mini(character_count, floori(_typing_elapsed * TYPEWRITER_CHARACTERS_PER_SECOND))
	if _text_label.visible_characters >= character_count:
		_typing = false
		_text_label.visible_characters = -1


func _reveal_current_line() -> void:
	_typing = false
	if _text_label != null:
		_text_label.visible_characters = -1


func _build_sensor() -> void:
	var sensor := Area2D.new()
	sensor.name = "ConversationRange"
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 118.0
	collision.shape = shape
	sensor.add_child(collision)
	sensor.body_entered.connect(_on_body_entered)
	sensor.body_exited.connect(_on_body_exited)
	add_child(sensor)


func _build_bubble() -> void:
	_panel = Control.new()
	_panel.name = "DialogueBubble"
	_panel.position = BUBBLE_OFFSET
	_panel.custom_minimum_size = Vector2(BUBBLE_WIDTH, BUBBLE_HEIGHT)
	_panel.size = Vector2(BUBBLE_WIDTH, BUBBLE_HEIGHT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := TextureRect.new()
	background.name = "PixelBubbleArt"
	background.texture = BUBBLE_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 72)
	margin.clip_contents = true
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.name = "VBoxContainer"
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	_speaker_label = _make_label(9, Color("ffd45f"))
	_speaker_label.name = "Speaker"
	_speaker_label.text = speaker_name.to_upper()
	stack.add_child(_speaker_label)
	_text_label = _make_label(10, Color.WHITE)
	_text_label.name = "Line"
	_text_label.custom_minimum_size = Vector2(BUBBLE_WIDTH - 68.0, 66.0)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.clip_text = true
	stack.add_child(_text_label)
	_hint_label = _make_label(8, Color("9fd9ff"))
	_hint_label.name = "Hint"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stack.add_child(_hint_label)
	add_child(_panel)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.add_theme_font_override("font", DIALOGUE_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("080511"))
	label.add_theme_constant_override("outline_size", 1)
	return label


func _refresh() -> void:
	if _panel == null:
		return
	_speaker_label.text = speaker_name.to_upper()
	if _active:
		_panel.visible = true
		_text_label.text = current_line()
		_hint_label.text = "[F / X] SIGUIENTE  %d/%d" % [_line_index + 1, lines.size()]
	elif _player_nearby and not _finished and not auto_start:
		_panel.visible = true
		_text_label.text = "Hablar"
		_hint_label.text = "[F / X] HABLAR"
	else:
		_panel.visible = false


func _on_body_entered(body: Node2D) -> void:
	if not body is PlayerController:
		return
	_player_nearby = true
	_nearby_player = body as PlayerController
	player_proximity_changed.emit(body as PlayerController, true)
	if auto_start:
		start()
	else:
		_refresh()


func _on_body_exited(body: Node2D) -> void:
	if not body is PlayerController:
		return
	_player_nearby = false
	_nearby_player = null
	player_proximity_changed.emit(body as PlayerController, false)
	if _active:
		_active = false
		_typing = false
	_refresh()


func _is_nearest_speaker() -> bool:
	if _nearby_player == null:
		return true
	var distance := global_position.distance_squared_to(_nearby_player.global_position)
	for node: Node in get_tree().get_nodes_in_group("npc_dialogue_bubbles"):
		var other := node as NpcDialogueBubble
		if other == self or other._nearby_player != _nearby_player or other._finished:
			continue
		var other_distance := other.global_position.distance_squared_to(_nearby_player.global_position)
		if other_distance < distance or (is_equal_approx(other_distance, distance) and other.get_instance_id() < get_instance_id()):
			return false
	return true
