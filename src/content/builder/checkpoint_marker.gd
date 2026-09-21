class_name CheckpointMarker
extends Area2D

signal activated(checkpoint_id: StringName, respawn_position: Vector2)

var checkpoint_id: StringName = &"checkpoint"
var respawn_position: Vector2 = Vector2.ZERO
var _active: bool = false
var _sprite: Sprite2D


func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(54.0, 110.0)
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	_sprite = Sprite2D.new()
	_sprite.name = "CheckpointArt"
	_sprite.texture = load("res://assets/art/props/world_0/checkpoint_capsule.png") as Texture2D
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * World0ArtMetrics.CHECKPOINT_SCALE
	_sprite.position.y = (
		-float(_sprite.texture.get_height()) * World0ArtMetrics.CHECKPOINT_SCALE * 0.5
	)
	add_child(_sprite)
	_update_art()
	queue_redraw()


func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-48.0, 66.0), "CHECKPOINT", HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if _active or not body is PlayerController:
		return
	_active = true
	_update_art()
	queue_redraw()
	activated.emit(checkpoint_id, respawn_position)


func _update_art() -> void:
	if _sprite != null:
		_sprite.modulate = Color("b9ffcf") if _active else Color.WHITE
