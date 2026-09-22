extends GdUnitTestSuite

const BALL_TEMPLATE_PATH := "res://assets/art/art_bible/ball_generation/ball_profile.template.json"
const ANARCHY_BALL_PROFILE_PATH := "res://assets/art/art_bible/ball_generation/anarchy_ball.example.json"
const WORLD0_ROSTER_PATH := "res://assets/art/art_bible/ball_generation/world0_ball_roster.json"
const DEFENSIVE_MISSILE_PATH := "res://assets/art/vfx/world_0/defensive_missile.png"
const FRONTIER_ENVIRONMENT_PATHS: Array[String] = [
	"res://assets/art/world_0/frontier_forest/tileset.png",
	"res://assets/art/world_0/frontier_forest/front_tree.png",
	"res://assets/art/world_0/frontier_forest/plant_1.png",
	"res://assets/art/world_0/frontier_forest/plant_2.png",
]
const RUNTIME_VISUAL_PATHS: Array[String] = [
	"res://assets/art/actors/balls/world_0/runtime/anarchy_ball_visual.tres",
	"res://assets/art/actors/balls/world_0/runtime/merchant_ball_visual.tres",
	"res://assets/art/actors/balls/world_0/runtime/robber_ball_visual.tres",
	"res://assets/art/actors/balls/world_0/runtime/egoist_ball_visual.tres",
	"res://assets/art/actors/balls/world_0/runtime/mutualist_ball_visual.tres",
	"res://assets/art/actors/balls/world_0/runtime/occupancy_enforcer_ball_visual.tres",
	"res://assets/art/actors/balls/world_0/runtime/ancom_ball_visual.tres",
]
const WORLD0_PROP_PATHS: Array[String] = [
	"res://assets/art/props/world_0/machine_console.png",
	"res://assets/art/props/world_0/machine_table.png",
	"res://assets/art/props/world_0/checkpoint_capsule.png",
	"res://assets/art/props/world_0/pickup_supply.png",
	"res://assets/art/props/world_0/pickup_payment.png",
	"res://assets/art/props/world_0/pickup_salvage.png",
]


func test_ball_prototype_variants_keep_the_approved_source_canvases() -> void:
	var prototype := PixelBallPrototype.new()
	prototype.variant = PixelBallPrototype.Variant.COMPACT_24_X_32
	assert_int(prototype.source_canvas().x).is_equal(24)
	assert_int(prototype.source_canvas().y).is_equal(32)
	prototype.variant = PixelBallPrototype.Variant.DETAIL_32_X_32
	assert_int(prototype.source_canvas().x).is_equal(32)
	assert_int(prototype.source_canvas().y).is_equal(32)
	prototype.free()


func test_ball_prototype_ignores_zero_facing_and_accepts_visual_states() -> void:
	var prototype := PixelBallPrototype.new()
	prototype.facing_direction = -1.0
	prototype.set_facing(0.0)
	assert_float(prototype.facing_direction).is_equal(-1.0)
	prototype.set_visual_state(PixelBallPrototype.VisualState.SURRENDERING)
	assert_int(prototype.visual_state).is_equal(PixelBallPrototype.VisualState.SURRENDERING)
	prototype.free()


func test_reusable_ball_profiles_share_the_approved_sheet_contract() -> void:
	var template := _load_json(BALL_TEMPLATE_PATH)
	var anarchy_ball := _load_json(ANARCHY_BALL_PROFILE_PATH)
	for profile: Dictionary in [template, anarchy_ball]:
		var sheet: Dictionary = profile["sheet"]
		assert_int(int(sheet["cell_width"])).is_equal(96)
		assert_int(int(sheet["cell_height"])).is_equal(96)
		assert_int(int(sheet["columns"])).is_equal(8)
		assert_int(int(sheet["rows"])).is_equal(8)
		assert_int(int(sheet["origin_x"])).is_equal(48)
		assert_int(int(sheet["origin_y"])).is_equal(90)
		assert_int(int(sheet["runtime_scale"])).is_equal(1)
		assert_bool(profile["eyes"]["white_only"]).is_true()
		assert_bool(profile["eyes"]["pupils"]).is_false()


func test_world0_roster_has_unique_ids_and_loadable_concept_assets() -> void:
	var roster := _load_json(WORLD0_ROSTER_PATH)
	var balls: Array = roster["balls"]
	assert_int(balls.size()).is_equal(9)
	var ids: Dictionary = {}
	for value: Variant in balls:
		var entry := value as Dictionary
		var ball_id := String(entry["ball_id"])
		assert_bool(ids.has(ball_id)).is_false()
		ids[ball_id] = true
		assert_bool(ResourceLoader.exists(String(entry["concept_path"]), "Texture2D")).is_true()


func test_world0_runtime_visuals_use_exact_atlas_contracts() -> void:
	for path: String in RUNTIME_VISUAL_PATHS:
		var definition := load(path) as BallVisualDefinition
		assert_object(definition).is_not_null()
		assert_bool(definition.is_valid()).is_true()
		assert_int(definition.keypose_atlas.get_width()).is_equal(768)
		assert_int(definition.keypose_atlas.get_height()).is_equal(96)
		assert_object(definition.animation_atlas).is_not_null()
		assert_int(definition.animation_atlas.get_width()).is_equal(definition.cell_size.x * definition.animation_columns)
		assert_int(definition.animation_atlas.get_height()).is_equal(definition.cell_size.y * 8)
		assert_object(definition.action_equipment).is_not_null()
		assert_vector(definition.action_equipment_socket).is_equal(Vector2(-35.0, -10.0))
		assert_bool(definition.action_equipment_behind_body).is_true()
		assert_float(definition.facing_scale_for(1.0)).is_equal(-1.0)
		assert_float(definition.facing_scale_for(-1.0)).is_equal(1.0)
		assert_float(definition.facing_scale_for(1.0, &"action")).is_equal(-1.0)
		assert_float(definition.facing_scale_for(-1.0, &"action")).is_equal(1.0)
		for state_id: StringName in [
			&"idle", &"move", &"jump", &"action", &"hurt",
			&"threatening", &"surrendering", &"neutralized",
		]:
			assert_int(definition.frame_for(state_id)).is_between(0, 7)
			assert_int(definition.row_for(state_id)).is_between(0, 7)
			assert_int(definition.frame_count_for(state_id)).is_between(4, 8)
			assert_float(definition.fps_for(state_id)).is_greater(0.0)


func test_every_ball_state_contains_at_least_four_distinct_animation_frames() -> void:
	for path: String in RUNTIME_VISUAL_PATHS:
		var definition := load(path) as BallVisualDefinition
		var atlas := definition.animation_atlas.get_image()
		for state_id: StringName in [
			&"idle", &"move", &"jump", &"action", &"hurt",
			&"threatening", &"surrendering", &"neutralized",
		]:
			var unique_frames: Dictionary = {}
			var row := definition.row_for(state_id)
			for frame: int in range(definition.frame_count_for(state_id)):
				var cell := atlas.get_region(Rect2i(Vector2i(frame, row) * definition.cell_size, definition.cell_size))
				unique_frames[hash(cell.get_data())] = true
			assert_int(unique_frames.size()).is_greater_equal(4)


func test_ancom_action_frames_keep_horizontal_transparency_gutters() -> void:
	var definition := load("res://assets/art/actors/balls/world_0/runtime/ancom_ball_visual.tres") as BallVisualDefinition
	var atlas := definition.animation_atlas.get_image()
	var row := definition.row_for(&"action")
	for frame: int in range(definition.frame_count_for(&"action")):
		var cell := atlas.get_region(Rect2i(Vector2i(frame, row) * definition.cell_size, definition.cell_size))
		for y: int in range(definition.cell_size.y):
			assert_float(cell.get_pixel(0, y).a).is_less(0.01)
			assert_float(cell.get_pixel(definition.cell_size.x - 1, y).a).is_less(0.01)


func test_ancom_diagonal_red_extends_below_forehead_in_every_frame() -> void:
	var definition := load("res://assets/art/actors/balls/world_0/runtime/ancom_ball_visual.tres") as BallVisualDefinition
	var atlas := definition.texture().get_image()
	var visual := auto_free(BallVisual.new()) as BallVisual
	visual.definition = definition
	add_child(visual)
	for row: int in 8:
		for frame: int in 8:
			var body := definition.frame_body_bounds[row * 8 + frame]
			var red_lower_left: int = 0
			for y: int in range(int(body.position.y + body.size.y * 0.5), int(body.end.y)):
				for x: int in range(int(body.position.x), int(body.get_center().x)):
					var color := atlas.get_pixel(frame * 157 + x, row * 157 + y)
					if color.a > 0.5 and color.r > 0.25 and color.r > color.g * 2.0 and color.r > color.b * 1.8:
						red_lower_left += 1
			assert_int(red_lower_left).is_greater(60)
			visual._state_id = [&"idle", &"move", &"jump", &"action", &"hurt", &"threatening", &"surrendering", &"neutralized"][row]
			visual._elapsed = float(frame) / definition.fps_for(visual._state_id)
			visual._update_frame()
			var sprite := visual.get_node("KeyposeSprite") as Sprite2D
			assert_vector(body.size * sprite.scale).is_equal(Vector2(76, 76))
			var foot := sprite.position + (Vector2(body.get_center().x, body.end.y) - Vector2(definition.cell_size) * 0.5) * sprite.scale
			assert_float(foot.y).is_equal_approx(18.0, 0.01)


func test_ancom_subdued_keyposes_do_not_include_side_particles() -> void:
	var keyposes := (load("res://assets/art/actors/balls/world_0/runtime/ancom_ball_keyposes.png") as Texture2D).get_image()
	var surrender := keyposes.get_region(Rect2i(6 * 96, 0, 96, 96))
	var neutralized := keyposes.get_region(Rect2i(7 * 96, 0, 96, 96))
	var surrender_bounds := _visible_alpha_bounds(surrender)
	var neutralized_bounds := _visible_alpha_bounds(neutralized)
	assert_int(surrender_bounds.size.x).is_less_equal(76)
	assert_int(neutralized_bounds.size.x).is_less_equal(76)
	assert_int(hash(surrender.get_data())).is_not_equal(hash(neutralized.get_data()))


func test_enemy_ball_visible_size_matches_anarchy_ball() -> void:
	var anarchy := (load("res://assets/art/actors/balls/world_0/runtime/anarchy_ball_visual.tres") as BallVisualDefinition).animation_atlas.get_image()
	var frontier := (load("res://assets/art/actors/balls/world_0/runtime/robber_ball_visual.tres") as BallVisualDefinition).animation_atlas.get_image()
	var anarchy_bounds := _visible_alpha_bounds(anarchy.get_region(Rect2i(0, 0, 96, 96)))
	var frontier_bounds := _visible_alpha_bounds(frontier.get_region(Rect2i(0, 0, 96, 96)))
	assert_int(absi(frontier_bounds.size.x - anarchy_bounds.size.x)).is_less_equal(3)
	# Antennae, hats, and carried equipment may alter total height without shrinking the ball body.
	assert_int(absi(frontier_bounds.size.y - anarchy_bounds.size.y)).is_less_equal(12)


func _visible_alpha_bounds(image: Image, alpha_threshold: float = 0.5) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a < alpha_threshold:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func test_defensive_projectile_uses_the_curated_two_frame_missile() -> void:
	var missile_texture := load(DEFENSIVE_MISSILE_PATH) as Texture2D
	assert_object(missile_texture).is_not_null()
	assert_int(missile_texture.get_width()).is_equal(32)
	assert_int(missile_texture.get_height()).is_equal(10)
	var hostile_bolt := load("res://src/combat/sandbox/hostile_bolt.tscn").instantiate() as HostileBolt
	var hostile_sprite := hostile_bolt.get_node("MissileSprite") as Sprite2D
	assert_object(hostile_sprite.texture).is_same(missile_texture)
	assert_int(hostile_sprite.hframes).is_equal(2)
	hostile_bolt.free()
	var probe_scene := load("res://src/combat/sandbox/aim_probe.tscn") as PackedScene
	var probe: Node = auto_free(probe_scene.instantiate()) as Node
	var sprite := probe.get_node("MissileSprite") as Sprite2D
	assert_int(sprite.hframes).is_equal(2)
	var player_scene := load("res://src/actors/player/player.tscn") as PackedScene
	var player: Node = auto_free(player_scene.instantiate()) as Node
	var launcher := player.get_node("ProbeLauncher") as SandboxProbeLauncher
	assert_vector(launcher.position).is_equal(Vector2(0.0, -10.0))
	assert_float(launcher.muzzle_distance).is_equal(55.0)


func test_world0_environment_uses_curated_terrain_and_props() -> void:
	for path: String in FRONTIER_ENVIRONMENT_PATHS:
		assert_bool(ResourceLoader.exists(path, "Texture2D")).is_true()
		assert_object(load(path) as Texture2D).is_not_null()
	assert_float(World0ArtMetrics.TERRAIN_SCALE).is_equal(3.0)
	assert_float(World0ArtMetrics.SCENERY_PROP_SCALE).is_equal(World0ArtMetrics.TERRAIN_SCALE)
	assert_float(World0ArtMetrics.MACHINE_SCALE).is_equal(2.0)
	assert_float(fmod(World0ArtMetrics.MACHINE_SCALE, 1.0)).is_equal(0.0)
	assert_float(World0ArtMetrics.PICKUP_SCALE).is_equal(World0ArtMetrics.TERRAIN_SCALE)
	assert_float(fmod(World0ArtMetrics.CHECKPOINT_SCALE, 1.0)).is_equal(0.0)
	for scene_path: String in [
		"res://levels/world_0/w0_01_first_aggression.tscn",
		"res://levels/world_0/w0_02_contract_bridge.tscn",
		"res://levels/world_0/w0_03_occupancy_workshop.tscn",
	]:
		var scene := load(scene_path) as PackedScene
		assert_object(scene).is_not_null()
		var builder := auto_free(scene.instantiate()) as LevelBuilder
		assert_object(builder.presentation_scene).is_not_null()
		assert_float(builder.art_surface_depth).is_equal(32.0)
	for path: String in WORLD0_PROP_PATHS:
		assert_bool(ResourceLoader.exists(path, "Texture2D")).is_true()
		assert_object(load(path) as Texture2D).is_not_null()


func test_world0_scenery_stays_behind_terrain_and_uses_integer_pixel_scale() -> void:
	var scene := load("res://levels/world_0/presentation/world0_frontier_presentation.tscn") as PackedScene
	var presentation := auto_free(scene.instantiate()) as Node2D
	var load_result := LevelSpecLoader.load_file("res://data/levels/w0_01_first_aggression.json")
	assert_bool(load_result.is_success()).is_true()
	presentation.call("configure", load_result.spec)
	var terrain := presentation.get_node("TerrainArt") as Node2D
	var props := presentation.get_node("SceneryProps") as Node2D
	var pillar := props.get_node("FrontierProp0") as Sprite2D
	assert_int(props.z_index).is_less(terrain.z_index)
	assert_vector(pillar.scale).is_equal(Vector2.ONE * World0ArtMetrics.SCENERY_PROP_SCALE)


func test_world0_background_layers_have_ordered_horizontal_parallax() -> void:
	var scene := load("res://levels/world_0/presentation/world0_frontier_presentation.tscn") as PackedScene
	var presentation := auto_free(scene.instantiate()) as Node2D
	var load_result := LevelSpecLoader.load_file("res://data/levels/w0_01_first_aggression.json")
	assert_bool(load_result.is_success()).is_true()
	presentation.call("configure", load_result.spec)
	var sky := presentation.get_node("Sky") as Parallax2D
	var mountains := presentation.get_node("Mountains") as Parallax2D
	var far_trees := presentation.get_node("FarTrees") as Parallax2D
	var near_trees := presentation.get_node("NearTrees") as Parallax2D
	assert_float(sky.scroll_scale.x).is_less(mountains.scroll_scale.x)
	assert_float(mountains.scroll_scale.x).is_less(far_trees.scroll_scale.x)
	assert_float(far_trees.scroll_scale.x).is_less(near_trees.scroll_scale.x)
	assert_float(near_trees.scroll_scale.x).is_less(1.0)
	for layer: Parallax2D in [sky, mountains, far_trees, near_trees]:
		assert_float(layer.scroll_scale.y).is_equal(1.0)
		assert_vector(layer.repeat_size).is_not_equal(Vector2.ZERO)
		assert_int(layer.repeat_times).is_equal(3)


func test_conflict_status_icons_use_six_cell_pixel_atlas() -> void:
	var texture := load("res://assets/art/ui/status_icons_16bit_v1.png") as Texture2D
	assert_object(texture).is_not_null()
	assert_vector(texture.get_size()).is_equal(Vector2(192.0, 32.0))
	var icon := auto_free(ConflictStatusIcon.new()) as ConflictStatusIcon
	add_child(icon)
	var sprite := icon.get_node("StatusSprite") as Sprite2D
	var glow := icon.get_node("EmissionGlow") as Sprite2D
	assert_int(sprite.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_int(glow.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
	icon.set_state(ConflictStateComponent.State.AGGRESSOR)
	assert_float(sprite.region_rect.position.x).is_equal(96.0)
	assert_float(glow.region_rect.position.x).is_equal(96.0)
	icon._process(0.1)
	assert_vector(glow.scale).is_not_equal(Vector2.ONE)


func test_world0_interactive_props_rest_on_the_collision_surface() -> void:
	var machine := auto_free(RuleStateObject.new()) as RuleStateObject
	add_child(machine)
	var machine_art := machine.get_node("MachineArt") as Sprite2D
	assert_int(machine_art.z_index).is_less(0)
	var machine_bottom := (
		machine_art.position.y
		+ float(machine_art.texture.get_height()) * machine_art.scale.y * 0.5
	)
	assert_float(machine_bottom).is_equal(0.0)
	var checkpoint := auto_free(CheckpointMarker.new()) as CheckpointMarker
	add_child(checkpoint)
	var checkpoint_art := checkpoint.get_node("CheckpointArt") as Sprite2D
	var checkpoint_bottom := (
		checkpoint_art.position.y
		+ float(checkpoint_art.texture.get_height()) * checkpoint_art.scale.y * 0.5
	)
	assert_float(checkpoint_bottom).is_equal(0.0)
	var platforms: Array = [
		{"id": "ground", "x": 100.0, "y": 600.0, "width": 500.0},
		{"id": "upper", "x": 300.0, "y": 525.0, "width": 120.0},
	]
	assert_float(WorldPropPlacement.grounded_y(platforms, 200.0, 545.0, 32.0)).is_equal(632.0)
	assert_float(WorldPropPlacement.grounded_y(platforms, 350.0, 500.0, 32.0)).is_equal(557.0)
	assert_float(WorldPropPlacement.grounded_y(platforms, 900.0, 545.0, 32.0)).is_equal(577.0)
	assert_vector(WorldPropPlacement.grounded_position(platforms, 350.0, 500.0, 32.0)).is_equal(Vector2(350.0, 557.0))
	assert_vector(
		WorldPropPlacement.grounded_position(
			platforms,
			350.0,
			500.0,
			32.0,
			WorldPropPlacement.BALL_ORIGIN_TO_FLOOR
		)
	).is_equal(Vector2(350.0, 533.0))


func test_art_backed_platform_places_physics_inside_the_road_tile() -> void:
	var platform := auto_free(DebugPlatform.new()) as DebugPlatform
	platform.size = Vector2(320.0, 100.0)
	platform.art_backed = true
	platform.collision_surface_depth = 32.0
	add_child(platform)
	var collision := platform.get_child(0) as CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	assert_float(collision.position.y).is_equal(32.0)
	assert_vector(shape.size).is_equal(Vector2(320.0, 100.0))


func test_thin_workshop_ledges_are_one_way_and_do_not_block_from_below() -> void:
	var platform := auto_free(DebugPlatform.new()) as DebugPlatform
	platform.size = Vector2(360.0, 24.0)
	add_child(platform)
	var collision := platform.get_child(0) as CollisionShape2D
	assert_bool(collision.one_way_collision).is_true()


func test_world0_elevated_floor_uses_ruin_cap_and_continuous_column_supports() -> void:
	var scene := load("res://levels/world_0/presentation/world0_frontier_presentation.tscn") as PackedScene
	var presentation := auto_free(scene.instantiate()) as Node2D
	var load_result := LevelSpecLoader.load_file("res://data/levels/w0_01_first_aggression.json")
	assert_bool(load_result.is_success()).is_true()
	presentation.call("configure", load_result.spec)
	var terrain := presentation.get_node("TerrainArt") as Node2D
	var ground_sprite := terrain.get_node("ground_onboardingTop0") as Sprite2D
	var ledge_sprite := terrain.get_node("aim_ruin_entryTop0") as Sprite2D
	var ground_atlas := ground_sprite.texture as AtlasTexture
	var ledge_atlas := ledge_sprite.texture as AtlasTexture
	assert_vector(ground_atlas.region.position).is_equal(Vector2.ZERO)
	assert_vector(ledge_atlas.region.position).is_equal(Vector2(112.0, 32.0))
	assert_vector(ledge_atlas.region.size).is_equal(Vector2(32.0, 16.0))
	assert_object(terrain.get_node_or_null("aim_ruin_entryBacking")).is_not_null()
	var support_columns := terrain.find_children("aim_ruin_entrySupport*_0", "Sprite2D", false, false)
	assert_int(support_columns.size()).is_greater_equal(6)


func test_workshop_required_climb_uses_column_floor_instead_of_road_art() -> void:
	var scene := load("res://levels/world_0/presentation/world0_frontier_presentation.tscn") as PackedScene
	var presentation := auto_free(scene.instantiate()) as Node2D
	var load_result := LevelSpecLoader.load_file("res://data/levels/w0_03_occupancy_workshop.json")
	assert_bool(load_result.is_success()).is_true()
	presentation.call("configure", load_result.spec)
	var terrain := presentation.get_node("TerrainArt") as Node2D
	var ledge := terrain.get_node("production_upperTop0") as Sprite2D
	var ledge_atlas := ledge.texture as AtlasTexture
	assert_vector(ledge_atlas.region.position).is_equal(Vector2(112.0, 32.0))
	assert_object(terrain.get_node_or_null("production_upperBacking")).is_not_null()
	assert_int(terrain.find_children("production_upperSupport*_0", "Sprite2D", false, false).size()).is_greater_equal(2)


func test_world0_optional_platforms_keep_a_jump_safety_margin() -> void:
	var profile := load("res://data/player/default_movement_profile.tres") as PlayerMovementProfile
	var safe_jump_rise := MovementMath.maximum_jump_height(profile) * 0.9
	var safe_horizontal_reach := MovementMath.conservative_horizontal_reach(profile)
	for spec_path: String in [
		"res://data/levels/w0_01_first_aggression.json",
		"res://data/levels/w0_02_contract_bridge.json",
		"res://data/levels/w0_03_occupancy_workshop.json",
	]:
		var spec := _load_json(spec_path)
		var platforms := spec.get("platforms", []) as Array
		var reachable: Array = platforms.filter(func(value: Dictionary) -> bool: return bool(value.get("required", true)))
		# Grow from the baseline route, including lift top stops and intermediate
		# ledges. Unreachable cycles must not validate one another.
		for _iteration: int in platforms.size():
			for candidate: Dictionary in platforms:
				if candidate in reachable:
					continue
				for source: Dictionary in reachable.duplicate():
					var gap := maxf(0.0, maxf(float(candidate.x) - float(source.x) - float(source.width), float(source.x) - float(candidate.x) - float(candidate.width)))
					var source_y := float(source.y) + minf(0.0, float(source.get("motion_distance_y", 0.0)))
					if gap <= safe_horizontal_reach and source_y - float(candidate.y) <= safe_jump_rise:
						reachable.append(candidate)
						break
		for platform_value: Variant in platforms:
			var platform := platform_value as Dictionary
			if not bool(platform.get("required", true)):
				assert_bool(platform in reachable).is_true()


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_object(file).is_not_null()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_int(typeof(parsed)).is_equal(TYPE_DICTIONARY)
	return parsed as Dictionary
