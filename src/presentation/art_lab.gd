class_name ArtLab
extends Node2D

const STATE_DURATION: float = 1.4

@export var compact_concept: Texture2D
@export var detailed_concept: Texture2D

@onready var compact_ball: PixelBallPrototype = %CompactBall
@onready var detailed_ball: PixelBallPrototype = %DetailedBall

var _state_index: int = 0
var _state_elapsed: float = 0.0
var _facing: float = 1.0


func _ready() -> void:
	_build_overlay()
	_apply_state()


func _process(delta: float) -> void:
	_state_elapsed += delta
	if _state_elapsed >= STATE_DURATION:
		_state_elapsed = 0.0
		_state_index = (_state_index + 1) % PixelBallPrototype.VisualState.size()
		_apply_state()
	var movement := InputActions.movement_axis()
	if not is_zero_approx(movement):
		_facing = signf(movement)
		compact_ball.set_facing(_facing)
		detailed_ball.set_facing(_facing)
	var aim := InputActions.directional_aim_vector()
	if aim.length_squared() > 0.04:
		compact_ball.set_aim(aim)
		detailed_ball.set_aim(aim)
	if InputActions.is_interact_just_pressed():
		_state_elapsed = 0.0
		_state_index = (_state_index + 1) % PixelBallPrototype.VisualState.size()
		_apply_state()


func _apply_state() -> void:
	var state := _state_index as PixelBallPrototype.VisualState
	compact_ball.set_visual_state(state)
	detailed_ball.set_visual_state(state)


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ArtLabOverlay"
	add_child(layer)
	var header := ColorRect.new()
	header.position = Vector2(18.0, 14.0)
	header.size = Vector2(1244.0, 204.0)
	header.color = Color("0d1022dc")
	layer.add_child(header)
	var title := Label.new()
	title.position = Vector2(20.0, 10.0)
	title.size = Vector2(1200.0, 30.0)
	title.text = "ART LAB · POLISHED PIXEL ART · IDEOLOGY SURFACE STUDY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	_add_concept(header, compact_concept, Vector2(25.0, 44.0), "EXPLORACIÓN ANTERIOR · acabado y volumen")
	_add_concept(header, detailed_concept, Vector2(630.0, 44.0), "DIRECCIÓN V2 · superficie ancap · ojos sin pupilas")
	var note := Label.new()
	note.position = Vector2(18.0, 650.0)
	note.size = Vector2(1244.0, 52.0)
	note.text = "Prototipos exactos: 24×32 a la izquierda · 32×32 a la derecha · escala 3×\nMover: acciones izquierda/derecha · apuntar: acciones de aim · INTERACT cambia estado"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", Color("fff4ec"))
	note.add_theme_color_override("font_shadow_color", Color("0b0712"))
	note.add_theme_constant_override("shadow_offset_x", 2)
	note.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(note)


func _add_concept(parent: Control, texture: Texture2D, position: Vector2, caption: String) -> void:
	var frame := TextureRect.new()
	frame.position = position
	frame.size = Vector2(570.0, 125.0)
	frame.texture = texture
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(frame)
	var label := Label.new()
	label.position = position + Vector2(0.0, 125.0)
	label.size = Vector2(570.0, 24.0)
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)
