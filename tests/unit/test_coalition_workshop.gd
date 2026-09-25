extends GdUnitTestSuite


func _build() -> LevelBuilder:
	var scene := load("res://levels/world_0/w0_01_coalition_workshop.tscn") as PackedScene
	var builder := auto_free(scene.instantiate()) as LevelBuilder
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.last_validation.is_valid()).is_true()
	return builder


func test_part_two_flankers_use_real_content_and_gate_resolution() -> void:
	var builder := _build()
	var observer := builder.get_node("Generated/EncounterObservers/p2_flank_intro") as EncounterRuntimeObserver
	var challenge := observer.challenge
	assert_int(observer._actors.size()).is_equal(2)
	assert_int(challenge.definition.mode).is_equal(CeasefireChallengeDefinition.AttackMode.AUTONOMOUS_FLANK)
	assert_bool(challenge.definition.any_surrender_resolves).is_false()
	for actor: CombatTarget in observer._actors:
		assert_object(actor._ball_visual).is_not_null()
		assert_float(actor.resolve.maximum_resolve).is_equal(75.0)
	var gate := builder.get_node("Generated/Gates/gate_p2_flank_intro") as AccessGate
	assert_bool(gate.try_open()).is_false()
	builder._player.global_position = Vector2(21560, 330)
	challenge.advance(challenge.definition.warning_seconds + 0.01)
	assert_bool(challenge.started).is_true()
	challenge.remaining = 0.01
	challenge.advance(0.02)
	assert_bool(observer.is_resolved()).is_true()
	assert_bool(gate.is_open()).is_true()
	assert_float(gate.position.y + 72.0).is_equal(350.0 + World0ArtMetrics.COLLISION_SURFACE_DEPTH)
	var economy := builder.get_node("Generated/Economy") as WorkshopEconomy
	assert_object(builder.get_node("Generated/shop_part_two")).is_not_null()
	assert_int(economy.shops.size()).is_equal(3)


func test_left_libertarian_resource_has_four_frames_per_state_and_single_frame_briefing() -> void:
	var definition := load("res://assets/art/actors/balls/world_0/runtime/left_libertarian_ball_visual.tres") as BallVisualDefinition
	assert_bool(definition.is_valid()).is_true()
	var source := (definition.animation_atlas as AtlasTexture).atlas
	assert_str(source.resource_path).is_equal("res://assets/art/actors/balls/world_0/runtime/left_libertarian_animation_v2.png")
	for state: StringName in [&"idle", &"move", &"jump", &"action", &"hurt", &"surrendering"]:
		assert_int(definition.frame_count_for(state)).is_equal(4)
	var flow := auto_free(SliceFlowController.new()) as SliceFlowController
	var frame := flow._briefing_texture({"image_path": source.resource_path, "image_columns": 4, "image_rows": 4, "image_frame": 0}) as AtlasTexture
	assert_float(frame.region.size.x).is_equal(frame.region.size.y)
	assert_float(frame.region.size.y).is_less(float(definition.animation_atlas.get_height()))
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	for card: Dictionary in spec.data.slice.briefing_cards:
		if not card.has("image_path"):
			continue
		assert_bool(ResourceLoader.exists(String(card.image_path))).is_true()
		if String(card.image_path).contains("left_libertarian"):
			assert_str(String(card.image_path)).is_equal(source.resource_path)
		var portrait := flow._briefing_texture(card)
		assert_object(portrait).is_not_null()
		assert_float(float(portrait.get_width())).is_equal(float(portrait.get_height()))


func test_scenery_sits_above_terrain_and_unused_stations_are_removed() -> void:
	var builder := _build()
	var presentation := builder.get_node("Generated/Presentation")
	var props := presentation.get_node("WorkshopStations") as Node2D
	var terrain := presentation.get_node("TerrainArt") as Node2D
	assert_int(props.z_index).is_greater(terrain.z_index)
	var count := 0
	for node: Node in props.get_children():
		if node is Sprite2D:
			var sprite := node as Sprite2D
			var used := sprite.texture.get_image().get_used_rect()
			var bottom := sprite.position.y + (used.end.y - sprite.texture.get_height() * 0.5) * sprite.scale.y
			var left := sprite.position.x + (used.position.x - sprite.texture.get_width() * 0.5) * sprite.scale.x
			var right := left + used.size.x * sprite.scale.x
			var supported := false
			for platform: Dictionary in builder.loaded_spec.data.platforms:
				if left >= float(platform.x) - 0.01 and right <= float(platform.x) + float(platform.width) + 0.01 and is_equal_approx(bottom, float(platform.y) + World0ArtMetrics.COLLISION_SURFACE_DEPTH):
					supported = true
			assert_bool(supported).override_failure_message(String(sprite.name) + " needs full-width support").is_true()
			for gate: Dictionary in builder.loaded_spec.data.gates:
				assert_bool(right <= float(gate.x) - 90.0 + 0.01 or left >= float(gate.x) + 90.0 - 0.01).is_true()
			assert_bool(sprite.z_as_relative).is_false()
			count += 1
	assert_int(count).is_greater_equal(30)
	assert_object(builder.get_node_or_null("Generated/RuleObjects/machine_current_press")).is_null()
	assert_object(builder.get_node_or_null("Generated/RuleObjects/machine_disputed_mill")).is_null()
	assert_object(builder.get_node_or_null("Generated/Actors/mutualist_claimant")).is_null()
	var economy := builder.get_node("Generated/Economy") as WorkshopEconomy
	assert_str(economy.shop._machine_sprite.texture.resource_path).contains("bitcoin_atm_terminal")


func test_dispatch_gate_blocks_transition_and_panel_releases_it() -> void:
	var builder := _build()
	var gate := builder.get_node("Generated/Gates/gate_dispatch") as AccessGate
	var bridge := builder.get_node("Generated/Platforms/dispatch_exit_bridge") as DebugPlatform
	var step := builder.get_node("Generated/Platforms/dispatch_exit_descent_last") as DebugPlatform
	var surface_y := step.position.y - step.size.y * 0.5 + step.collision_surface_depth
	assert_float(gate.position.x).is_greater(bridge.position.x + bridge.size.x * 0.5)
	assert_float(gate.position.y + gate.size.y * 0.5).is_equal(surface_y)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var query := PhysicsRayQueryParameters2D.create(Vector2(gate.position.x - 25.0, surface_y - 24.0), Vector2(gate.position.x + 60.0, surface_y - 24.0), 1)
	var space := gate.get_world_2d().direct_space_state
	assert_bool(space.intersect_ray(query).get("collider") == gate).is_true()
	var feeder := builder.get_node("Generated/RuleObjects/machine_dispatch_feeder") as RuleStateObject
	var panel := builder.get_node("Generated/RuleObjects/control_dispatch_exit") as RuleStateObject
	var economy := builder.get_node("Generated/Economy") as WorkshopEconomy
	economy.player.inventory.grant_once("test_service", {"service_parts": 10})
	assert_bool(feeder.interact()).is_false()
	assert_bool(economy.confirm_service()).is_true()
	assert_bool(panel.interact()).is_true()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(gate.is_open()).is_true()
	assert_bool(space.intersect_ray(query).is_empty()).is_true()


func test_new_level_preserves_old_roster_in_coordination_section() -> void:
	var builder := _build()
	assert_object(builder.get_node_or_null("Generated/Actors/black_facilitator")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/EncounterObservers/crew_ancom")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/EncounterObservers/crew_egoist")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/RuleObjects/crew_power")).is_not_null()
	assert_str(builder.loaded_spec.level_id()).is_equal("w0_01_coalition_workshop")


func test_local_relay_survives_central_interruption_without_replacing_power() -> void:
	var builder := _build()
	var crew := builder.get_node("Generated/crew_workshop_coordination") as CrewCoordination
	crew.assign_local(0, true)
	assert_bool(crew.channel_enabled(0)).is_false()
	crew.power_source.interact()
	var economy := builder.get_node("Generated/Economy") as WorkshopEconomy
	economy.player.inventory.grant_once("test_service", {"service_parts": 10})
	assert_bool(economy.confirm_service()).is_true()
	assert_bool(crew.channel_enabled(0)).is_true()
	assert_bool(crew.channel_enabled(1)).is_true()
	var actor := crew.disruptors[0]
	actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.DETAIN_ORDER_EXECUTED)
	crew.refresh()
	assert_bool(crew.platforms[0].is_rule_enabled()).is_true()
	assert_bool(crew.platforms[1].is_rule_enabled()).is_false()
	crew.assign_local(1, true)
	assert_bool(crew.platforms[1].is_rule_enabled()).is_true()
	crew.assign_local(0, false)
	assert_bool(crew.platforms[0].is_rule_enabled()).is_false()
	assert_bool(crew.platforms[1].is_rule_enabled()).is_true()


func test_coordination_checkpoint_restores_assignments_and_derived_routes() -> void:
	var builder := _build()
	var crew := builder.get_node("Generated/crew_workshop_coordination") as CrewCoordination
	crew.power_source.interact()
	var economy := builder.get_node("Generated/Economy") as WorkshopEconomy
	economy.player.inventory.grant_once("test_service", {"service_parts": 10})
	assert_bool(economy.confirm_service()).is_true()
	crew.assign_local(0, true)
	builder.activate_checkpoint(&"test_coordination", Vector2(14440, 600))
	crew.assign_local(0, false)
	crew.assign_local(1, true)
	builder.retry_from_checkpoint()
	assert_bool(crew.local_assignments[0]).is_true()
	assert_bool(crew.local_assignments[1]).is_false()
	assert_bool(crew.channel_enabled(0)).is_true()


func test_coordination_rejects_missing_and_duplicate_references() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	var setup := (load("res://data/content/crew_workshop_coordination.tres") as CrewCoordinationDefinition).duplicate() as CrewCoordinationDefinition
	assert_array(setup.validation_errors(spec)).is_empty()
	setup.platform_ids[1] = setup.platform_ids[0]
	assert_array(setup.validation_errors(spec)).is_not_empty()
	setup.platform_ids[0] = &"missing"
	assert_array(setup.validation_errors(spec)).is_not_empty()


func test_industrial_art_contains_no_forest_tiles_and_lift_uses_matching_deck() -> void:
	var builder := _build()
	var terrain := builder.get_node("Generated/Presentation/TerrainArt")
	for child: Node in terrain.get_children():
		if child is Sprite2D:
			var atlas := (child as Sprite2D).texture as AtlasTexture
			assert_bool(atlas.atlas.resource_path.contains("workshop_industrial")).is_true()
	var lift := builder.get_node("Generated/Platforms/platform_restored_lift") as DebugPlatform
	var art := lift.get_node("ElevatorTop0") as Sprite2D
	assert_bool((art.texture as AtlasTexture).atlas.resource_path.contains("workshop_industrial")).is_true()


func test_black_sheet_has_alpha_and_four_frames_per_state_with_stable_foot() -> void:
	_assert_calibrated_sheet("black_anarchy")


func test_left_sheet_has_alpha_and_four_distinct_frames_with_stable_foot() -> void:
	_assert_calibrated_sheet("left_libertarian")


func _assert_calibrated_sheet(id: String) -> void:
	var definition := load("res://assets/art/actors/balls/world_0/runtime/" + id + "_ball_visual.tres") as BallVisualDefinition
	assert_bool(definition.is_valid()).is_true()
	var visual := auto_free(BallVisual.new()) as BallVisual
	visual.definition = definition
	add_child(visual)
	var image := definition.texture().get_image()
	assert_int(image.detect_alpha()).is_not_equal(Image.ALPHA_NONE)
	assert_float(image.get_pixel(0, 0).a).is_less(0.01)
	for state: StringName in [&"idle", &"move", &"action", &"hurt", &"surrendering"]:
		visual.set_state(state)
		assert_int(definition.frame_count_for(state)).is_equal(4)
		var distinct: Dictionary = {}
		for frame: int in 4:
			var cell := Rect2i(frame * definition.cell_size.x, definition.row_for(state) * definition.cell_size.y, definition.cell_size.x, definition.cell_size.y)
			var content := image.get_region(cell)
			distinct[hash(content.get_data())] = true
			var bounds := BallVisualDefinition.visible_frame_bounds(content)
			assert_int(bounds.position.x).is_greater(0)
			assert_int(bounds.end.x).is_less(definition.cell_size.x)
			assert_int(bounds.position.y).is_greater(0)
			assert_int(bounds.end.y).is_less(definition.cell_size.y)
			visual._elapsed = float(frame) / definition.fps_for(state)
			visual._update_frame()
			var sprite := visual.get_node("KeyposeSprite") as Sprite2D
			var body := definition.frame_body_bounds[definition.row_for(state) * 4 + frame]
			var body_size := body.size * sprite.scale
			var foot := sprite.position + (Vector2(body.get_center().x, body.end.y) - Vector2(definition.cell_size) * 0.5) * sprite.scale
			assert_float(body_size.x).is_equal_approx(76.0, 0.01)
			assert_float(body_size.y).is_equal_approx(76.0, 0.01)
			assert_float(foot.x).is_equal_approx(0.0, 0.01)
			assert_float(foot.y).is_equal_approx(18.0, 0.01)
		assert_int(distinct.size()).is_equal(4)


func test_frame_fit_ignores_export_noise_without_modifying_source() -> void:
	var source := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	source.fill(Color(0, 0, 0, 1.0 / 255.0))
	source.set_pixel(2, 3, Color.WHITE)
	source.set_pixel(5, 6, Color.WHITE)
	assert_bool(BallVisualDefinition.visible_frame_bounds(source) == Rect2i(2, 3, 4, 4)).is_true()
	assert_float(source.get_pixel(0, 0).a).is_greater(0.0)
	source.fill(Color.TRANSPARENT)
	assert_bool(BallVisualDefinition.visible_frame_bounds(source) == Rect2i()).is_true()
