extends Node2D

const SOURCE_HEIGHT: float = 240.0
const ART_SCALE: float = World0ArtMetrics.TERRAIN_SCALE
const SOURCE_TILE_SIZE: float = 32.0
const WORLD_TILE_SIZE: float = SOURCE_TILE_SIZE * ART_SCALE
const ROAD_SURFACE_INSET: float = 5.0 * ART_SCALE
const LEDGE_SOURCE_HEIGHT: float = 16.0
const LEDGE_ATLAS_ORIGIN := Vector2(112.0, 32.0)
const COLUMN_ATLAS_REGION := Rect2(112.0, 64.0, 32.0, 48.0)
const GROUND_BOTTOM: float = 720.0
const PROP_SPACING: float = 1900.0
const TREE_SPACING: float = 3200.0
const FOREST_ROOT := "res://assets/art/world_0/frontier_forest/"


func configure(spec: LevelSpec) -> void:
	var bounds := spec.data.get("bounds", {}) as Dictionary
	var world_width := float(bounds.get("width", 1280.0))
	_build_layer("Sky", load("res://assets/art/world_0/frontier_forest/sky.png") as Texture2D, world_width, Color("ffffff"), World0ArtMetrics.SKY_PARALLAX, -4)
	_build_layer("Mountains", load("res://assets/art/world_0/frontier_forest/mountains.png") as Texture2D, world_width, Color("f4c9ff"), World0ArtMetrics.MOUNTAIN_PARALLAX, -3)
	_build_layer("FarTrees", load("res://assets/art/world_0/frontier_forest/far_trees.png") as Texture2D, world_width, Color("ffffff"), World0ArtMetrics.FAR_TREE_PARALLAX, -2)
	_build_layer("NearTrees", load("res://assets/art/world_0/frontier_forest/near_trees.png") as Texture2D, world_width, Color("ffffff"), World0ArtMetrics.NEAR_TREE_PARALLAX, -1)
	_build_terrain(spec)
	_build_midground_props(world_width)
	_build_forest_silhouettes(world_width)


func _build_layer(
	layer_name: String,
	texture: Texture2D,
	world_width: float,
	tint: Color,
	horizontal_scroll_scale: float,
	layer_z_index: int
) -> void:
	var parallax := Parallax2D.new()
	parallax.name = layer_name
	parallax.scroll_scale = Vector2(horizontal_scroll_scale, 1.0)
	parallax.repeat_size = Vector2(float(texture.get_width()) * ART_SCALE, 0.0)
	parallax.repeat_times = 3
	parallax.z_index = layer_z_index
	add_child(parallax)
	var sprite := Sprite2D.new()
	sprite.name = "Texture"
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, 0.0, ceilf(world_width / ART_SCALE), SOURCE_HEIGHT)
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.scale = Vector2(ART_SCALE, ART_SCALE)
	sprite.modulate = tint
	parallax.add_child(sprite)


func _build_terrain(spec: LevelSpec) -> void:
	var terrain := Node2D.new()
	terrain.name = "TerrainArt"
	terrain.z_index = 2
	add_child(terrain)
	var tileset := load(FOREST_ROOT + "tileset.png") as Texture2D
	var platforms := spec.data.get("platforms", []) as Array
	for platform_value: Variant in platforms:
		var data := platform_value as Dictionary
		if not is_zero_approx(float(data.get("motion_distance_y", 0.0))):
			continue
		var x := float(data.get("x", 0.0))
		var y := float(data.get("y", 0.0))
		var width := float(data.get("width", WORLD_TILE_SIZE))
		var height := float(data.get("height", 24.0))
		var required := bool(data.get("required", true))
		var art_style := String(data.get("art_style", "road" if required else "column_supported"))
		var uses_column_supports := art_style == "column_supported"
		if not uses_column_supports:
			var body := ColorRect.new()
			body.name = "%sBody" % String(data.get("id", "platform"))
			body.position = Vector2(x, y + WORLD_TILE_SIZE - ROAD_SURFACE_INSET)
			body.size = Vector2(width, maxf(height - WORLD_TILE_SIZE + ROAD_SURFACE_INSET, GROUND_BOTTOM - y - WORLD_TILE_SIZE + ROAD_SURFACE_INSET))
			body.color = Color("160b30")
			body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			terrain.add_child(body)
		else:
			var ground_y := _ground_surface_below(platforms, x, width, y)
			_add_platform_supports(terrain, tileset, x, y, width, ground_y, String(data.get("id", "platform")))
		var tile_count := maxi(1, ceili(width / WORLD_TILE_SIZE))
		for tile_index: int in tile_count:
			var source_column := tile_index % 3
			var tile_x := x + minf(float(tile_index) * WORLD_TILE_SIZE, width - WORLD_TILE_SIZE)
			_add_terrain_tile(
				terrain, tileset, tile_x, y, source_column,
				String(data.get("id", "platform")), tile_index, uses_column_supports
			)


func _add_terrain_tile(
	parent: Node2D,
	tileset: Texture2D,
	x: float,
	y: float,
	source_column: int,
	platform_id: String,
	tile_index: int,
	uses_column_supports: bool
) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = tileset
	atlas.region = (
		Rect2(Vector2(float(source_column) * SOURCE_TILE_SIZE, 0.0), Vector2(SOURCE_TILE_SIZE, SOURCE_TILE_SIZE))
		if not uses_column_supports
		else Rect2(LEDGE_ATLAS_ORIGIN, Vector2(SOURCE_TILE_SIZE, LEDGE_SOURCE_HEIGHT))
	)
	var sprite := Sprite2D.new()
	sprite.name = "%sTop%d" % [platform_id, tile_index]
	sprite.texture = atlas
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(x, y - ROAD_SURFACE_INSET)
	sprite.scale = Vector2(ART_SCALE, ART_SCALE)
	parent.add_child(sprite)


func _ground_surface_below(platforms: Array, x: float, width: float, y: float) -> float:
	var result := GROUND_BOTTOM
	for platform_value: Variant in platforms:
		var candidate := platform_value as Dictionary
		if not bool(candidate.get("required", true)):
			continue
		var candidate_x := float(candidate.get("x", 0.0))
		var candidate_width := float(candidate.get("width", 0.0))
		var candidate_y := float(candidate.get("y", GROUND_BOTTOM))
		var overlaps := x < candidate_x + candidate_width and x + width > candidate_x
		if overlaps and candidate_y > y:
			result = minf(result, candidate_y)
	return result


func _add_platform_supports(
	parent: Node2D,
	tileset: Texture2D,
	x: float,
	y: float,
	width: float,
	ground_y: float,
	platform_id: String
) -> void:
	var ledge_bottom := y - ROAD_SURFACE_INSET + LEDGE_SOURCE_HEIGHT * ART_SCALE
	var support_height := maxf(0.0, ground_y - ledge_bottom)
	if support_height < 8.0:
		return
	var backing := ColorRect.new()
	backing.name = "%sBacking" % platform_id
	backing.position = Vector2(x, ledge_bottom)
	backing.size = Vector2(width, support_height)
	backing.color = Color("150929e6")
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(backing)
	var support_count := maxi(1, ceili(width / WORLD_TILE_SIZE))
	for support_index: int in support_count:
		var support_x := x + minf(float(support_index) * WORLD_TILE_SIZE, width - WORLD_TILE_SIZE)
		var remaining_height := support_height
		var support_y := ledge_bottom
		var segment_index := 0
		while remaining_height > 0.0:
			var source_height := minf(COLUMN_ATLAS_REGION.size.y, remaining_height / ART_SCALE)
			var atlas := AtlasTexture.new()
			atlas.atlas = tileset
			atlas.region = Rect2(COLUMN_ATLAS_REGION.position, Vector2(COLUMN_ATLAS_REGION.size.x, source_height))
			var support := Sprite2D.new()
			support.name = "%sSupport%d_%d" % [platform_id, support_index, segment_index]
			support.texture = atlas
			support.centered = false
			support.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			support.position = Vector2(support_x, support_y)
			support.scale = Vector2(ART_SCALE, ART_SCALE)
			parent.add_child(support)
			var rendered_height := source_height * ART_SCALE
			support_y += rendered_height
			remaining_height -= rendered_height
			segment_index += 1


func _build_midground_props(world_width: float) -> void:
	var props := Node2D.new()
	props.name = "SceneryProps"
	props.z_index = 1
	add_child(props)
	var texture_paths: Array[String] = [FOREST_ROOT + "pillar.png", FOREST_ROOT + "plant_1.png", FOREST_ROOT + "plant_2.png"]
	var index := 0
	var x_position := 720.0
	while x_position < world_width:
		var texture := load(texture_paths[index % texture_paths.size()]) as Texture2D
		var sprite := Sprite2D.new()
		sprite.name = "FrontierProp%d" % index
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * World0ArtMetrics.SCENERY_PROP_SCALE
		sprite.position = Vector2(
			x_position,
			600.0 - float(texture.get_height()) * World0ArtMetrics.SCENERY_PROP_SCALE * 0.5
		)
		sprite.modulate = Color("eadcffd9")
		props.add_child(sprite)
		index += 1
		x_position += PROP_SPACING


func _build_forest_silhouettes(world_width: float) -> void:
	var trees := Node2D.new()
	trees.name = "ForestSilhouettes"
	trees.z_index = 1
	add_child(trees)
	var texture := load(FOREST_ROOT + "front_tree.png") as Texture2D
	var index := 0
	var x_position := 1450.0
	while x_position < world_width:
		var sprite := Sprite2D.new()
		sprite.name = "FrontTree%d" % index
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(1.55, 1.55)
		sprite.position = Vector2(x_position, 600.0 - texture.get_height() * 0.775)
		sprite.modulate = Color("b89bd5b8")
		trees.add_child(sprite)
		index += 1
		x_position += TREE_SPACING
