class_name ConflictStatusIcon
extends Node2D

const STATUS_ATLAS := preload("res://assets/art/ui/status_icons_16bit_v1.png")

var state: ConflictStateComponent.State = ConflictStateComponent.State.NEUTRAL
var _sprite: Sprite2D
var _glow_sprite: Sprite2D
var _elapsed: float = 0.0


func _ready() -> void:
	_glow_sprite = Sprite2D.new()
	_glow_sprite.name = "EmissionGlow"
	_glow_sprite.texture = STATUS_ATLAS
	_glow_sprite.region_enabled = true
	_glow_sprite.region_rect = Rect2(0.0, 0.0, 32.0, 32.0)
	_glow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow_sprite.z_index = -1
	var glow_material := CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_sprite.material = glow_material
	add_child(_glow_sprite)
	_sprite = Sprite2D.new()
	_sprite.name = "StatusSprite"
	_sprite.texture = STATUS_ATLAS
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0.0, 0.0, 32.0, 32.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_update_regions()


func _process(delta: float) -> void:
	_elapsed += delta
	if _glow_sprite == null:
		return
	var speed := 7.5 if state in [ConflictStateComponent.State.THREATENING, ConflictStateComponent.State.AGGRESSOR] else 3.5
	var pulse := (sin(_elapsed * speed) + 1.0) * 0.5
	var intensity := 0.20 + pulse * (0.55 if state in [ConflictStateComponent.State.THREATENING, ConflictStateComponent.State.AGGRESSOR] else 0.30)
	_glow_sprite.scale = Vector2.ONE * (1.05 + pulse * 0.16)
	_glow_sprite.modulate = Color(_state_glow_color(), intensity)


func set_state(value: ConflictStateComponent.State) -> void:
	if state == value:
		return
	state = value
	_elapsed = 0.0
	_update_regions()


func _update_regions() -> void:
	var region := Rect2(float(int(state) * 32), 0.0, 32.0, 32.0)
	if _sprite != null:
		_sprite.region_rect = region
	if _glow_sprite != null:
		_glow_sprite.region_rect = region


func _state_glow_color() -> Color:
	match state:
		ConflictStateComponent.State.DISPUTED: return Color("bb50ff")
		ConflictStateComponent.State.THREATENING: return Color("ffd23f")
		ConflictStateComponent.State.AGGRESSOR: return Color("ff334d")
		ConflictStateComponent.State.SURRENDERING: return Color("48ef78")
		ConflictStateComponent.State.NEUTRALIZED: return Color("83b9e8")
		_: return Color("35dfff")
