class_name CheckpointMarker
extends Area2D

signal activated(checkpoint_id: StringName, respawn_position: Vector2)

var checkpoint_id: StringName = &"checkpoint"
var respawn_position: Vector2 = Vector2.ZERO
var _active: bool = false
var _sprite: Sprite2D
var emergency_refill: Callable


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
	# Preserve footprint, but sample details on the same 3-world-pixel grid as terrain.
	var pixels := ShaderMaterial.new()
	pixels.shader = preload("res://assets/art/props/pickup_pixel_grid.gdshader")
	pixels.set_shader_parameter("logical_size", (_sprite.texture.get_size() / World0ArtMetrics.TERRAIN_SCALE).round())
	_sprite.material = pixels
	var beacon := InteractionBeacon.new()
	beacon.name = "InteractionBeacon"
	add_child(beacon)
	beacon.configure(_sprite, "CHECKPOINT", Color("65ffe0"))
	_update_art()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not body is PlayerController:
		return
	if emergency_refill.is_valid():
		emergency_refill.call()
	if _active:
		return
	_active = true
	_update_art()
	queue_redraw()
	activated.emit(checkpoint_id, respawn_position)


func _update_art() -> void:
	if _sprite != null:
		_sprite.modulate = Color("b9ffcf") if _active else Color.WHITE
