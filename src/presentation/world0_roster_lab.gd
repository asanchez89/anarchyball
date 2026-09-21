class_name World0RosterLab
extends Node2D

const ROSTER_PATH := "res://assets/art/art_bible/ball_generation/world0_ball_roster.json"
const BACKGROUND_PATH := "res://assets/art/world_0/frontier_forest/preview.png"
const COLUMNS: int = 3
const PANEL_SIZE := Vector2(410.0, 196.0)


func _ready() -> void:
	_build_background()
	_build_roster()


func _build_background() -> void:
	var background := TextureRect.new()
	background.name = "TwilightForestReference"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load(BACKGROUND_PATH) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.modulate = Color("5b5268")
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	layer.add_child(background)


func _build_roster() -> void:
	var file := FileAccess.open(ROSTER_PATH, FileAccess.READ)
	if file == null:
		push_error("World 0 roster manifest is missing")
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		push_error("World 0 roster manifest is invalid")
		return
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.position = Vector2(20.0, 10.0)
	title.size = Vector2(1240.0, 42.0)
	title.text = "WORLD 0 · BALL ROSTER + TWILIGHT ASSET COMPATIBILITY LAB"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("fff4ec"))
	layer.add_child(title)
	var balls: Array = data["balls"]
	for index: int in range(balls.size()):
		_add_ball_panel(layer, balls[index] as Dictionary, index)


func _add_ball_panel(layer: CanvasLayer, entry: Dictionary, index: int) -> void:
	var column := index % COLUMNS
	var row := index / COLUMNS
	var panel := ColorRect.new()
	panel.position = Vector2(16.0 + column * 421.0, 58.0 + row * 214.0)
	panel.size = PANEL_SIZE
	panel.color = Color("100d1ed8")
	layer.add_child(panel)
	var image := TextureRect.new()
	image.position = Vector2(8.0, 8.0)
	image.size = Vector2(394.0, 146.0)
	image.texture = load(String(entry["concept_path"])) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(image)
	var label := Label.new()
	label.position = Vector2(8.0, 157.0)
	label.size = Vector2(394.0, 32.0)
	label.text = "%s · %s" % [entry["display_name"], entry["role"]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("fff4ec"))
	panel.add_child(label)
