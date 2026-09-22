class_name InteractionBeacon
extends Node2D
## Shared presentation only: never owns interaction or collision.

@export var caption: String = ""
@export var tint: Color = Color("65ffe0")
@export var pulse_seconds: float = 2.4
@export var minimum_alpha: float = 0.35
var _halo: Sprite2D
var _time: float = 0.0
var _bounds: Rect2
var actionable: bool = true


func configure(art: Sprite2D, text: String, color: Color) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	caption = text
	tint = color
	var used := art.texture.get_image().get_used_rect()
	_bounds = Rect2(art.position + (Vector2(used.position) - art.texture.get_size() * 0.5) * art.scale, Vector2(used.size) * art.scale)
	_halo = Sprite2D.new()
	_halo.texture = preload("res://assets/art/props/pickup_presentation.tres").aura_texture
	_halo.position = _bounds.get_center()
	_halo.scale = (_bounds.size + Vector2(54, 36)) / _halo.texture.get_size()
	_halo.z_index = -2
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_halo.material = blend
	add_child(_halo)
	if not caption.is_empty():
		var sign := Label.new()
		sign.name = "Sign"
		sign.text = caption
		sign.position = Vector2(-90, _bounds.position.y - 36)
		sign.size = Vector2(180, 24)
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.add_theme_font_override("font", preload("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf"))
		sign.add_theme_font_size_override("font_size", 12)
		sign.add_theme_color_override("font_color", tint)
		sign.add_theme_color_override("font_outline_color", Color("101329"))
		sign.add_theme_constant_override("outline_size", 4)
		add_child(sign)
	_process(0.0)
	queue_redraw()


func set_status(text: String, available: bool) -> void:
	actionable = available
	if caption != text:
		caption = text
		var sign := get_node_or_null("Sign") as Label
		if sign != null:
			sign.text = caption
		queue_redraw()
	modulate = Color.WHITE if available else Color("929ba9")
	if _halo != null:
		_halo.visible = available


func _process(delta: float) -> void:
	_time += delta
	if _halo != null:
		_halo.modulate = Color(tint, lerpf(minimum_alpha, 0.75, (sin(_time * TAU / pulse_seconds) + 1.0) * 0.5))


func _draw() -> void:
	if caption.is_empty():
		return
	var width := float(caption.length() * 12 + 18)
	var plate := Rect2(-width * 0.5, _bounds.position.y - 40, width, 27)
	draw_rect(plate, Color("101329"))
	draw_rect(plate, tint.darkened(0.4), false, 3.0)
