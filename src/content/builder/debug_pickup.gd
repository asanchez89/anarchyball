class_name DebugPickup
extends Area2D

signal collected(pickup_id: StringName)

var pickup_id: StringName = &""
var pickup_kind: StringName = &""
var ownership: StringName = &"unowned_collectible"
var effect_id: StringName = &""
var effect_amount: float = 0.0
var _collected: bool = false
var _available: bool = true
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	_sprite = Sprite2D.new()
	_sprite.name = "PickupArt"
	_sprite.texture = _texture_for_kind()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * World0ArtMetrics.PICKUP_SCALE
	add_child(_sprite)
	queue_redraw()


func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-65.0, 38.0), String(ownership), HORIZONTAL_ALIGNMENT_CENTER, 130.0, 10, Color.WHITE)


func _texture_for_kind() -> Texture2D:
	var kind_text := String(pickup_kind)
	if "payment" in kind_text or "reward" in kind_text:
		return load("res://assets/art/props/world_0/pickup_payment.png") as Texture2D
	if "salvage" in kind_text or "spares" in kind_text:
		return load("res://assets/art/props/world_0/pickup_salvage.png") as Texture2D
	return load("res://assets/art/props/world_0/pickup_supply.png") as Texture2D


func is_collected() -> bool:
	return _collected


func restore_collected(value: bool) -> void:
	_collected = value
	_apply_availability()


func set_available(value: bool) -> void:
	_available = value
	_apply_availability()


func is_available() -> bool:
	return _available


func _on_body_entered(body: Node2D) -> void:
	if _collected or not _available or not body is PlayerController:
		return
	_apply_effect(body as PlayerController)
	_collected = true
	visible = false
	set_deferred("monitoring", false)
	collected.emit(pickup_id)


func _apply_effect(player: PlayerController) -> void:
	if effect_id == &"health_restore":
		(player.get_node("Health") as HealthComponent).heal(effect_amount)


func _apply_availability() -> void:
	visible = _available and not _collected
	monitoring = _available and not _collected
