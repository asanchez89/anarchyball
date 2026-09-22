class_name BallVisual
extends Node2D

@export var definition: BallVisualDefinition

var _sprite: Sprite2D
var _action_equipment: Sprite2D
var _state_id: StringName = &"idle"
var _elapsed: float = 0.0
var _facing_direction: float = 1.0
var _equipment_rest_position := Vector2.ZERO
var _equipment_base_scale: float = 1.0
var _visible_regions: Array[Rect2] = []


func _process(delta: float) -> void:
	_elapsed += delta
	_update_frame()


func _ready() -> void:
	_rebuild()


func configure(value: BallVisualDefinition) -> void:
	definition = value
	if is_node_ready():
		_rebuild()


func set_state(state_id: StringName) -> void:
	if _state_id == state_id:
		return
	_state_id = state_id
	_elapsed = 0.0
	_apply_facing()
	_update_frame()


func set_facing(direction: float) -> void:
	if definition == null or is_zero_approx(direction):
		return
	_facing_direction = direction
	_apply_facing()


func set_action_equipment(texture: Texture2D, flipped: bool = false, art_scale: float = 1.0) -> void:
	_equipment_base_scale = maxf(0.1, art_scale)
	if _action_equipment != null:
		_action_equipment.texture = texture
		_action_equipment.flip_h = flipped
		_update_frame()


func _apply_facing() -> void:
	if definition == null:
		return
	scale.x = definition.facing_scale_for(_facing_direction, _state_id)


func _rebuild() -> void:
	if _sprite != null:
		_sprite.queue_free()
	if _action_equipment != null:
		_action_equipment.queue_free()
	_sprite = null
	_action_equipment = null
	if definition == null or not definition.is_valid():
		return
	_sprite = Sprite2D.new()
	_sprite.name = "KeyposeSprite"
	_sprite.texture = definition.texture()
	_sprite.region_enabled = true
	_sprite.centered = true
	# El baseline fuente y=30 aterriza cerca del borde inferior del collider de 48 px.
	_sprite.position = Vector2(0.0, -24.0)
	_sprite.scale = Vector2.ONE * definition.runtime_scale
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_visible_regions.clear()
	if definition.fit_visible_frame_height > 0.0 and definition.frame_body_bounds.is_empty():
		var source := definition.texture().get_image()
		if source.is_compressed():
			source.decompress()
		for row: int in source.get_height() / definition.cell_size.y:
			for column: int in definition.animation_columns:
				var cell := Rect2i(Vector2i(column, row) * definition.cell_size, definition.cell_size)
				var used := BallVisualDefinition.visible_frame_bounds(source.get_region(cell))
				_visible_regions.append(Rect2(used.position + cell.position, used.size))
	if definition.action_equipment != null:
		_action_equipment = Sprite2D.new()
		_action_equipment.name = "ActionEquipment"
		_action_equipment.texture = definition.action_equipment
		_action_equipment.position = definition.action_equipment_socket
		_equipment_rest_position = definition.action_equipment_socket
		_action_equipment.z_index = -1 if definition.action_equipment_behind_body else 1
		_action_equipment.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_action_equipment)
	_update_frame()


func _update_frame() -> void:
	if _sprite == null or definition == null:
		return
	var row := 0
	var frame := definition.frame_for(_state_id)
	if definition.animation_atlas != null:
		row = definition.row_for(_state_id)
		frame = int(_elapsed * definition.fps_for(_state_id)) % definition.frame_count_for(_state_id)
	_sprite.region_rect = Rect2(
		Vector2(frame * definition.cell_size.x, row * definition.cell_size.y),
		Vector2(definition.cell_size)
	)
	if not definition.frame_body_bounds.is_empty():
		var body := definition.frame_body_bounds[row * definition.animation_columns + frame]
		_sprite.scale = definition.runtime_body_size / body.size
		_sprite.position = Vector2(0.0, definition.body_ground_y) - (Vector2(body.get_center().x, body.end.y) - Vector2(definition.cell_size) * 0.5) * _sprite.scale
	elif not _visible_regions.is_empty():
		var region := _visible_regions[row * definition.animation_columns + frame]
		_sprite.region_rect = region
		var art_scale := definition.fit_visible_frame_height / maxf(1.0, region.size.y)
		_sprite.scale = Vector2.ONE * art_scale
		_sprite.position.y = 18.0 - definition.fit_visible_frame_height * 0.5
	if _action_equipment != null:
		_action_equipment.visible = _state_id == &"action"
		if _action_equipment.visible:
			var action_phase := frame % definition.frame_count_for(&"action")
			var recoil: float = [0.0, 1.0, 4.0, 7.0, 4.0, 2.0, 1.0, 0.0][action_phase]
			_action_equipment.position = _equipment_rest_position + Vector2(recoil, 0.0)
			var equipment_scale: float = [0.96, 1.0, 1.08, 1.14, 1.08, 1.03, 1.0, 0.98][action_phase]
			_action_equipment.scale = Vector2.ONE * equipment_scale * _equipment_base_scale
		else:
			_action_equipment.position = _equipment_rest_position
			_action_equipment.scale = Vector2.ONE * _equipment_base_scale
