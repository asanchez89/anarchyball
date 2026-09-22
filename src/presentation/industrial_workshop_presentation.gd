extends "res://src/presentation/world0_frontier_presentation.gd"

const INDUSTRIAL_ROOT := "res://assets/art/world_0/workshop_industrial/"
const DECK := Rect2(80, 96, 32, 16)
const FLOOR := Rect2(32, 80, 32, 16)
const BRACE := Rect2(176, 128, 32, 32)
const PANEL := Rect2(96, 128, 64, 32)


func configure(spec: LevelSpec) -> void:
	var background := load(INDUSTRIAL_ROOT + "background.png") as Texture2D
	var parallax := Parallax2D.new()
	parallax.name = "WorkshopInterior"
	parallax.scroll_scale = Vector2(0.25, 1.0)
	parallax.repeat_size = Vector2(background.get_width() * ART_SCALE, 0)
	parallax.repeat_times = 3
	parallax.z_index = -3
	add_child(parallax)
	for row: int in ceili(720.0 / (background.get_height() * ART_SCALE)):
		var sprite := Sprite2D.new()
		sprite.texture = background
		sprite.centered = false
		sprite.scale = Vector2.ONE * ART_SCALE
		sprite.position.y = row * background.get_height() * ART_SCALE
		sprite.modulate = Color("91a4b6")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parallax.add_child(sprite)
	_build_terrain(spec)
	_build_authored_scenery(spec)


func configure_platform_visual(platform: DebugPlatform) -> void:
	platform.moving_art_region = DECK
	platform.configure_motion(platform.motion_distance_y(), platform.motion_speed(), load(INDUSTRIAL_ROOT + "tileset.png") as Texture2D)


func _build_terrain(spec: LevelSpec) -> void:
	var terrain := Node2D.new()
	terrain.name = "TerrainArt"
	terrain.z_index = 2
	add_child(terrain)
	var texture := load(INDUSTRIAL_ROOT + "tileset.png") as Texture2D
	var platforms := spec.data.get("platforms", []) as Array
	for data: Dictionary in platforms:
		var id := String(data.id)
		var x := float(data.x)
		var y := float(data.y)
		var width := float(data.width)
		var motion := float(data.get("motion_distance_y", 0))
		var bottom := _ground_surface_below(platforms, x, width, y)
		if not is_zero_approx(motion):
			var track := load(INDUSTRIAL_ROOT + "lift_track.png") as Texture2D
			for side: int in 2:
				var rail_x := x + (width - 24.0) * side
				_tile_region(terrain, track, Rect2(Vector2.ZERO, track.get_size()), Rect2(rail_x, y + motion, 24, bottom - y - motion), id + "Guide%d" % side)
			continue
		var supported := String(data.get("art_style", "road")) == "column_supported"
		# Surface contact is 32px into the visual tile, shared with all grounded objects.
		_tile_region(terrain, texture, DECK if supported else FLOOR, Rect2(x, y + 8, width, 48), id + "Top")
		if not supported:
			_tile_region(terrain, texture, PANEL, Rect2(x, y + 56, width, maxf(0, 720 - y - 56)), id + "Body")
		else:
			for column: int in maxi(1, ceili(width / 192.0)):
				var column_x := x + minf(column * 192.0, maxf(0, width - 96))
				var column_bottom := _ground_surface_below(platforms, column_x, minf(96, width), y)
				_tile_region(terrain, texture, BRACE, Rect2(column_x, y + 56, minf(96, width), maxf(0, column_bottom - y - 56)), id + "Support%d_" % column)


func _tile_region(parent: Node2D, texture: Texture2D, source: Rect2, destination: Rect2, prefix: String) -> void:
	var tile_size := source.size * ART_SCALE
	for row: int in ceili(destination.size.y / tile_size.y):
		for column: int in ceili(destination.size.x / tile_size.x):
			var offset := Vector2(column, row) * tile_size
			var visible_size := (destination.size - offset).min(tile_size)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(source.position, visible_size / ART_SCALE)
			var sprite := Sprite2D.new()
			sprite.name = prefix + "%d_%d" % [column, row]
			sprite.texture = atlas
			sprite.centered = false
			sprite.scale = Vector2.ONE * ART_SCALE
			sprite.position = destination.position + offset
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			parent.add_child(sprite)
