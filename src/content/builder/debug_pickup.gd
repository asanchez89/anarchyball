class_name DebugPickup
extends Area2D

signal collected(pickup_id: StringName)
signal expired(pickup_id: StringName)

@export var presentation: PickupPresentationProfile = preload("res://assets/art/props/pickup_presentation.tres")

var pickup_id: StringName = &""
var pickup_kind: StringName = &""
var ownership: StringName = &"unowned_collectible"
var effect_id: StringName = &""
var effect_amount: float = 0.0
var _collected: bool = false
var _available: bool = true
var _sprite: Sprite2D
var inventory_reward: Dictionary = {}
var display_text: String = ""
var _aura: Sprite2D
var lifetime_seconds: float = 0.0
var warning_seconds: float = 0.0
var remaining_seconds: float = 0.0
var _expired: bool = false
var _visual_time: float = 0.0
var _collection_shape: CollisionShape2D
var _drop_elapsed: float = 0.0
var _drop_active: bool = false
var _drop_start := Vector2.ZERO
var _drop_end := Vector2.ZERO


func set_art(atlas: Texture2D, region: Rect2, art_scale: float = -1.0) -> void:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	_sprite.texture = texture
	_sprite.material = null
	if art_scale > 0.0:
		_sprite.scale = Vector2.ONE * art_scale
	_sync_collection_shape()


func set_pixel_grid_art(atlas: Texture2D, region: Rect2, visible_size: float, pixel_size: float) -> void:
	set_art(atlas, region)
	var logical := (region.size / maxf(region.size.x, region.size.y) * roundf(visible_size / pixel_size)).round().max(Vector2.ONE)
	_sprite.scale = logical * pixel_size / region.size
	var grid := ShaderMaterial.new()
	grid.shader = preload("res://assets/art/props/pickup_pixel_grid.gdshader")
	grid.set_shader_parameter("source_origin", region.position / atlas.get_size())
	grid.set_shader_parameter("source_extent", region.size / atlas.get_size())
	grid.set_shader_parameter("logical_size", logical)
	_sprite.material = grid
	_sync_collection_shape()


func visible_art_rect() -> Rect2:
	var bounds := Rect2(_sprite.texture.get_image().get_used_rect())
	return Rect2((bounds.position - _sprite.texture.get_size() * 0.5) * _sprite.scale, bounds.size * _sprite.scale)


func _sync_collection_shape() -> void:
	if _sprite == null or _collection_shape == null:
		return
	var bounds := visible_art_rect()
	var shape := RectangleShape2D.new()
	shape.size = (bounds.size + Vector2.ONE * presentation.collection_padding * 2.0).max(Vector2.ONE * presentation.minimum_collection_size)
	_collection_shape.shape = shape
	_collection_shape.position = bounds.get_center()
	_aura.position = bounds.get_center()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_collection_shape = CollisionShape2D.new()
	_collection_shape.name = "CollectionShape"
	add_child(_collection_shape)
	body_entered.connect(_on_body_entered)
	_aura = Sprite2D.new()
	_aura.name = "CollectibleAura"
	_aura.texture = presentation.aura_texture
	_aura.scale = Vector2.ONE * presentation.aura_diameter / _aura.texture.get_width()
	_aura.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_aura.material = glow
	add_child(_aura)
	_sprite = Sprite2D.new()
	_sprite.name = "PickupArt"
	_sprite.texture = _texture_for_kind()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * World0ArtMetrics.PICKUP_SCALE
	add_child(_sprite)
	_sync_collection_shape()
	_apply_availability()


func _physics_process(delta: float) -> void:
	advance_drop(delta)
	# Also handles a pickup becoming available while the player already overlaps.
	if not monitoring or not _available or _collected or _expired or is_queued_for_deletion():
		return
	for body: Node2D in get_overlapping_bodies():
		_on_body_entered(body)
		if _collected:
			break


func launch_drop(origin: Vector2, landing: Vector2) -> void:
	_drop_start = origin
	_drop_end = landing
	_drop_elapsed = 0.0
	_drop_active = true
	position = origin
	set_available(true)


func advance_drop(delta: float) -> void:
	if not _drop_active or not _available or _collected or _expired or is_queued_for_deletion():
		return
	if is_inside_tree() and get_tree().paused:
		return
	_drop_elapsed = minf(presentation.drop_arc_seconds, _drop_elapsed + maxf(0.0, delta))
	var progress := _drop_elapsed / presentation.drop_arc_seconds
	position = _drop_start.lerp(_drop_end, progress) + Vector2.UP * (4.0 * presentation.drop_arc_height * progress * (1.0 - progress))
	if _drop_elapsed >= presentation.drop_arc_seconds:
		_drop_active = false
		position = _drop_end


func capture_drop_motion() -> Dictionary:
	# Primitive fields remain JSON-compatible in the checkpoint payload.
	return {"active": _drop_active, "elapsed": _drop_elapsed, "start_x": _drop_start.x, "start_y": _drop_start.y, "end_x": _drop_end.x, "end_y": _drop_end.y}


func restore_drop_motion(state: Dictionary) -> void:
	_drop_active = bool(state.get("active", false))
	_drop_elapsed = clampf(float(state.get("elapsed", 0.0)), 0.0, presentation.drop_arc_seconds)
	_drop_start = Vector2(float(state.get("start_x", position.x)), float(state.get("start_y", position.y)))
	_drop_end = Vector2(float(state.get("end_x", position.x)), float(state.get("end_y", position.y)))


func configure_lifetime(duration: float, warning: float) -> void:
	lifetime_seconds = duration
	warning_seconds = warning
	remaining_seconds = duration
	_expired = false


func _process(delta: float) -> void:
	advance_lifetime(delta)
	if not _expired:
		_visual_time += delta
		_update_collectible_visual()


func advance_lifetime(delta: float) -> void:
	if lifetime_seconds <= 0.0 or not _available or _collected or _expired or is_queued_for_deletion():
		return
	if is_inside_tree() and get_tree().paused:
		return
	var previous_second := ceili(remaining_seconds)
	remaining_seconds = maxf(0.0, remaining_seconds - maxf(0.0, delta))
	if ceili(remaining_seconds) != previous_second:
		queue_redraw()
	if remaining_seconds <= 0.0:
		_expired = true
		_apply_availability()
		expired.emit(pickup_id)
		queue_free()


func is_expiring() -> bool:
	return lifetime_seconds > 0.0 and remaining_seconds <= warning_seconds and not _expired and not _collected and _available


func restore_lifetime(remaining: float) -> void:
	remaining_seconds = clampf(remaining, 0.0, lifetime_seconds)
	_expired = false
	_visual_time = 0.0
	_update_collectible_visual()
	queue_redraw()


func _update_collectible_visual() -> void:
	if _aura == null or _sprite == null:
		return
	var pulse := (sin(_visual_time * TAU / presentation.pulse_seconds) + 1.0) * 0.5
	_aura.modulate.a = lerpf(presentation.pulse_minimum, 1.0, pulse)
	var dim := is_expiring() and fmod(_visual_time * presentation.warning_blinks_per_second, 1.0) >= 0.5
	_sprite.modulate.a = presentation.warning_dim_alpha if dim else 1.0


func visible_floor_offset() -> float:
	var texture := _sprite.texture
	var image := texture.get_image()
	return (float(image.get_used_rect().end.y) - texture.get_height() * 0.5) * _sprite.scale.y


func _draw() -> void:
	var lines := (display_text if not display_text.is_empty() else String(ownership)).split(" · ")
	for index: int in lines.size():
		draw_string(ThemeDB.fallback_font, Vector2(-130.0, 48.0 + index * 16.0), lines[index], HORIZONTAL_ALIGNMENT_CENTER, 260.0, 12, Color.WHITE)
	if is_expiring():
		draw_string(ThemeDB.fallback_font, Vector2(-130.0, -42.0), "DESAPARECE EN %d s" % ceili(remaining_seconds), HORIZONTAL_ALIGNMENT_CENTER, 260.0, 12, Color("ffdb55"))


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
	if _drop_active and _drop_elapsed < presentation.drop_collection_delay:
		return
	if _collected or _expired or not _available or is_queued_for_deletion() or not body is PlayerController:
		return
	if not inventory_reward.is_empty():
		var inventory := (body as PlayerController).inventory
		if inventory == null:
			return
		inventory.grant_once(String(pickup_id), inventory_reward.get("items", {}), int(inventory_reward.get("sats", 0)))
	_apply_effect(body as PlayerController)
	_collected = true
	_apply_availability()
	collected.emit(pickup_id)
	if lifetime_seconds > 0.0:
		queue_free()


func _apply_effect(player: PlayerController) -> void:
	if effect_id == &"health_restore":
		(player.get_node("Health") as HealthComponent).heal(effect_amount)


func _apply_availability() -> void:
	var active := _available and not _collected and not _expired
	visible = active
	set_process(active)
	set_physics_process(active)
	set_deferred("monitoring", active)
	queue_redraw()
