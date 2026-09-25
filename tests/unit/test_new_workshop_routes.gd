extends GdUnitTestSuite


func test_archive_reservations_reference_real_supplies_without_biography_runtime() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/level_design/w0_01_archive_reservations.json"))
	assert_bool(metadata.editorial_only).is_true()
	assert_int(metadata.reservations.size()).is_equal(3)
	for reservation: Dictionary in metadata.reservations:
		assert_bool(reservation.author_id == null).is_true()
		var platforms: Array = spec.data.platforms.filter(func(p: Dictionary) -> bool: return p.id == reservation.platform_id)
		var rewards: Array = spec.data.resources.filter(func(p: Dictionary) -> bool: return p.id == reservation.temporary_reward_id)
		assert_int(platforms.size()).is_equal(1)
		assert_int(rewards.size()).is_equal(1)
		assert_str(String(rewards[0].kind)).is_equal("supply")
		assert_float(float(rewards[0].x)).is_greater_equal(float(platforms[0].x))
		assert_float(float(rewards[0].x)).is_less_equal(float(platforms[0].x) + float(platforms[0].width))
		assert_float(float(rewards[0].y)).is_less(float(platforms[0].y))


func test_assembly_gallery_replaces_flat_bypass_and_keeps_supplies_above_solids() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	for platform: Dictionary in spec.data.platforms:
		var overlaps_gallery := float(platform.x) < 22220.0 and float(platform.x) + float(platform.width) > 21460.0
		if overlaps_gallery:
			assert_float(float(platform.y)).override_failure_message("Flat bypass under assembly: " + String(platform.id)).is_less_equal(350.0)
	for pickup: Dictionary in spec.data.resources:
		if float(pickup.x) < 21100.0 or float(pickup.x) >= 22580.0:
			continue
		for platform: Dictionary in spec.data.platforms:
			if float(pickup.x) <= float(platform.x) or float(pickup.x) >= float(platform.x) + float(platform.width):
				continue
			assert_bool(float(pickup.y) < float(platform.y) or float(pickup.y) > float(platform.y) + float(platform.height)).override_failure_message("Buried supply: " + String(pickup.id)).is_true()


func test_advanced_flank_exit_requires_ascent_and_resolved_gate() -> void:
	await _assert_exit_requires_ascent("p2_flank_exit_riser", "gate_p2_flank_vertical", "p2_factory_continuation")


func test_advanced_pulse_exit_requires_ascent_and_resolved_gate() -> void:
	await _assert_exit_requires_ascent("p3_pulse_exit_gallery", "gate_p3_pulse_advanced", "p3_factory_continuation")


func test_crew_return_step_does_not_create_a_bypass_under_the_gate() -> void:
	await _assert_exit_requires_ascent("crew_exit_return_low", "gate_crew_ancom", "crew_exit")


func _assert_exit_requires_ascent(riser_id: String, gate_id: String, floor_id: String) -> void:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	level._player.set_physics_process(false)
	for node: Node in level.find_children("*", "", true, false):
		if node is CombatTarget:
			node.set_process(false)
		elif node is CeasefireChallenge:
			node.set_physics_process(false)
	await get_tree().physics_frame
	var player := level._player
	var riser := level.get_node("Generated/Platforms/" + riser_id) as DebugPlatform
	var gate := level.get_node("Generated/Gates/" + gate_id) as AccessGate
	var lower := level.get_node("Generated/Platforms/" + floor_id) as DebugPlatform
	var riser_left := riser.position.x - riser.size.x * 0.5
	var floor_y := lower.position.y - lower.size.y * 0.5 + lower.collision_surface_depth - WorldPropPlacement.BALL_ORIGIN_TO_FLOOR
	var upper_y := riser.position.y - riser.size.y * 0.5 + riser.collision_surface_depth - WorldPropPlacement.BALL_ORIGIN_TO_FLOOR
	# Even with the encounter resolved, walking under the gallery cannot cross
	# the solid support. The rise must be climbed using the authored platforms.
	assert_bool(gate.open_for_resolution()).is_true()
	await get_tree().physics_frame
	player.reset_at(Vector2(riser_left - 60.0, floor_y))
	for frame: int in 50:
		player.velocity = Vector2(300.0, 40.0)
		player.move_and_slide()
		await get_tree().physics_frame
	assert_float(player.position.x).is_less(riser_left)
	gate.restore_open(false)
	await get_tree().physics_frame
	player.reset_at(Vector2(gate.position.x - 80.0, upper_y))
	for frame: int in 35:
		player.velocity = Vector2(300.0, 40.0)
		player.move_and_slide()
		await get_tree().physics_frame
	assert_float(player.position.x).is_less(gate.position.x)
	assert_bool(gate.open_for_resolution()).is_true()
	await get_tree().physics_frame
	for frame: int in 30:
		player.velocity = Vector2(300.0, 40.0)
		player.move_and_slide()
		await get_tree().physics_frame
	assert_float(player.position.x).is_greater(gate.position.x + gate.size.x)


func test_coalition_exit_has_solid_lower_block_and_clear_checkpoint() -> void:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var gallery := level.get_node("Generated/Platforms/coalition_exit_gallery") as DebugPlatform
	var gate := level.get_node("Generated/Gates/gate_p3_final_coalition") as AccessGate
	assert_float(gate.position.y + gate.size.y * 0.5).is_equal(gallery.position.y - gallery.size.y * 0.5 + gallery.collision_surface_depth)
	var ray := PhysicsRayQueryParameters2D.create(Vector2(38420, 650), Vector2(38920, 650), 1)
	var hit := level.get_world_2d().direct_space_state.intersect_ray(ray)
	assert_bool(hit.is_empty()).is_false()
	if not hit.is_empty():
		assert_object(hit.collider).is_same(gallery)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = (level._player.get_node("CollisionShape2D") as CollisionShape2D).shape
	query.collision_mask = 1
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	var checkpoints: Array = spec.data.checkpoints.filter(func(checkpoint: Dictionary) -> bool: return checkpoint.id == "checkpoint_final_safe")
	assert_int(checkpoints.size()).is_equal(1)
	for checkpoint: Dictionary in checkpoints:
		query.transform = Transform2D(0.0, Vector2(checkpoint.respawn_x, checkpoint.respawn_y))
		assert_array(level.get_world_2d().direct_space_state.intersect_shape(query)).is_empty()


func test_collective_entry_cover_blocks_low_shots_but_exposes_upper_angle() -> void:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var observer := level.get_node("Generated/EncounterObservers/p2_collective") as EncounterRuntimeObserver
	var cover := level.get_node("Generated/Platforms/p2_collective_entry_cover") as DebugPlatform
	var upper_angles := 0
	for actor: CombatTarget in observer._actors:
		var low_ray := PhysicsRayQueryParameters2D.create(Vector2(22770, 658), actor.global_position, 1)
		var low_hit := level.get_world_2d().direct_space_state.intersect_ray(low_ray)
		assert_bool(low_hit.is_empty()).override_failure_message("Entry still sees " + String(actor.stable_id)).is_false()
		if not low_hit.is_empty():
			assert_object(low_hit.collider).is_same(cover)
		for scene_path: String in ["res://src/combat/sandbox/aim_probe.tscn", "res://src/combat/sandbox/hostile_bolt.tscn"]:
			var projectile := auto_free(load(scene_path).instantiate()) as Area2D
			level.add_child(projectile)
			projectile.set_physics_process(false)
			projectile.global_position = low_ray.from
			projectile.set("direction", low_ray.from.direction_to(actor.global_position))
			projectile.set("speed", 3000.0)
			projectile.call("_physics_process", 1.0)
			assert_bool(projectile.is_queued_for_deletion()).override_failure_message(scene_path + ": real projectile crossed collective cover").is_true()
		var upper_ray := PhysicsRayQueryParameters2D.create(Vector2(22880, 578), actor.global_position, 1)
		if level.get_world_2d().direct_space_state.intersect_ray(upper_ray).is_empty():
			upper_angles += 1
	assert_int(upper_angles).is_greater(0)


func test_new_decks_form_reachable_base_movement_graph() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	var profile := load("res://data/player/default_movement_profile.tres") as PlayerMovementProfile
	var reached: Array[Dictionary] = []
	var pending: Array[Dictionary] = []
	for platform: Dictionary in spec.data.platforms:
		if float(platform.x) < 19900.0:
			continue
		if bool(platform.required):
			reached.append(platform)
		else:
			pending.append(platform)
	for iteration: int in pending.size():
		for platform: Dictionary in pending.duplicate():
			if reached.any(func(source: Dictionary) -> bool: return LevelValidator._can_jump(source, platform, profile)):
				reached.append(platform)
				pending.erase(platform)
	assert_array(pending).is_empty()


func test_new_steps_and_returns_are_physically_reachable_without_class_ability() -> void:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	assert_bool(level.last_validation.is_valid()).is_true()
	level._player.set_physics_process(false)
	for node: Node in level.find_children("*", "", true, false):
		if node is CombatTarget:
			node.set_process(false)
		elif node is CeasefireChallenge:
			node.set_physics_process(false)
	await get_tree().physics_frame
	var player := level._player
	var profile := player.movement_profile
	var legs: Array = [
		["p3_factory_continuation", 34610.0, "p3_pulse_advanced_lower", 34730.0],
		["p3_pulse_advanced_lower", 34870.0, "p3_pulse_advanced_upper", 35010.0],
		["p3_pulse_advanced_upper", 35140.0, "p3_pulse_exit_gallery", 35250.0, false],
		["p3_pulse_exit_gallery", 35250.0, "p3_pulse_advanced_upper", 35140.0, false],
		["p3_factory_continuation", 35800.0, "p3_pulse_exit_return", 35690.0],
		["p3_pulse_exit_return", 35610.0, "p3_pulse_exit_gallery", 35510.0],
		["p3_pulse_exit_gallery", 35510.0, "p3_pulse_exit_return", 35610.0, false],
		["p2_factory_continuation", 22770.0, "p2_collective_entry_cover", 22880.0],
		["p2_collective_entry_cover", 22880.0, "p2_factory_continuation", 22770.0, false],
		["p2_collective_entry_cover", 22890.0, "p2_collective_deck", 23030.0],
		["p2_collective_deck", 23030.0, "p2_collective_entry_cover", 22890.0],
		["coalition_lower", 37650.0, "coalition_marker_post", 37770.0],
		["coalition_marker_post", 37770.0, "coalition_lower", 37650.0, false],
		["coalition_upper", 38420.0, "coalition_exit_gallery", 38520.0, false],
		["coalition_exit_gallery", 38520.0, "coalition_upper", 38420.0, false],
		["p3_factory_continuation", 39200.0, "coalition_exit_return", 39090.0],
		["coalition_exit_return", 39020.0, "coalition_exit_gallery", 38920.0],
		["coalition_exit_gallery", 38920.0, "coalition_exit_return", 39020.0, false],
		["p2_flank_vertical_upper", 26300.0, "p2_heavy_cache", 26400.0],
		["p2_heavy_cache", 26400.0, "p2_flank_vertical_upper", 26300.0, false],
		["p2_factory_continuation", 25810.0, "p2_flank_vertical_deck", 25920.0],
		["p2_flank_vertical_upper", 26310.0, "p2_flank_exit_riser", 26400.0, false],
		["p2_flank_exit_riser", 26400.0, "p2_flank_vertical_upper", 26310.0, false],
		["p2_factory_continuation", 26810.0, "p2_flank_exit_return", 26700.0],
		["p2_flank_exit_return", 26630.0, "p2_flank_exit_riser", 26540.0],
		["p2_flank_exit_riser", 26540.0, "p2_flank_exit_return", 26630.0, false],
		["storage_step_two", 10170.0, "storage_step_three", 10270.0],
		["storage_step_three", 10400.0, "storage_top", 10500.0],
		["storage_step_two", 10170.0, "p1_salvage_underpass_entry", 10270.0, false],
		["p1_salvage_underpass_entry", 10320.0, "p1_salvage_underpass", 10420.0, false],
		["p1_salvage_underpass", 10420.0, "p1_salvage_underpass_entry", 10300.0],
		["p1_salvage_underpass_entry", 10260.0, "storage_step_two", 10150.0],
		["p3_factory_continuation", 33610.0, "p3_factory_continuation", 33110.0, false],
		["p3_factory_continuation", 33110.0, "p3_raiders_lower", 33230.0],
		["p3_raiders_lower", 33360.0, "p3_raiders_upper", 33500.0],
		["p3_raiders_upper", 33620.0, "p3_raid_exit_riser", 33750.0, false],
		["p3_raid_exit_riser", 33750.0, "p3_raiders_upper", 33620.0, false],
		["p3_raiders_upper", 33500.0, "p3_raiders_lower", 33360.0],
		["p3_factory_continuation", 34180.0, "p3_raid_exit_return", 34070.0],
		["p3_raid_exit_return", 34000.0, "p3_raid_exit_riser", 33910.0],
		["p3_pulse_advanced_upper", 35010.0, "p3_salvage_access", 34860.0],
		["p3_salvage_access", 34820.0, "p3_salvage_gallery", 34680.0],
		["p3_salvage_gallery", 34680.0, "p3_salvage_access", 34820.0],
		["p3_salvage_access", 34860.0, "p3_pulse_advanced_upper", 35010.0],
		["p2_factory_continuation", 23810.0, "p2_repair_cache_step", 23900.0],
		["p2_repair_cache_step", 23900.0, "p2_repair_cache", 23760.0],
		["p2_repair_cache", 23760.0, "p2_repair_cache_step", 23900.0],
		["p2_flank_vertical_upper", 26270.0, "p2_records_access", 26120.0],
		["p2_records_access", 26050.0, "p2_records_return", 25910.0],
		["p2_records_return", 25820.0, "p2_records_room", 25690.0],
		["p2_records_room", 25690.0, "p2_records_return", 25820.0],
		["p2_records_return", 25910.0, "p2_records_access", 26050.0],
		["p2_records_access", 26120.0, "p2_flank_vertical_upper", 26270.0],
		["production_step_two", 4670.0, "production_climb_middle", 4780.0],
		["production_climb_middle", 4780.0, "production_upper", 4910.0],
		["production_upper", 4910.0, "p1_archive_office_step", 4890.0],
		["p1_archive_office_step", 4920.0, "p1_archive_office_floor", 5040.0],
		["p1_archive_office_floor", 5040.0, "p1_archive_office_step", 4920.0],
		["production_descent_last", 6040.0, "production_return", 5910.0],
		["part_two_factory_floor", 21060.0, "p2_assembly_step_one", 21160.0],
		["p2_assembly_step_one", 21160.0, "p2_assembly_step_two", 21280.0],
		["p2_assembly_step_two", 21280.0, "p2_assembly_step_three", 21400.0],
		["p2_assembly_step_three", 21400.0, "p2_assembly_gallery", 21500.0],
		["p2_assembly_gallery", 21480.0, "p2_flank_intro_deck", 21610.0],
		["p2_flank_intro_deck", 21610.0, "p2_assembly_gallery", 21480.0],
		["p2_factory_continuation", 22620.0, "p2_assembly_return_low", 22520.0],
		["p2_assembly_return_low", 22520.0, "p2_assembly_return_mid", 22400.0],
		["p2_assembly_return_mid", 22400.0, "p2_assembly_return_high", 22280.0],
		["p2_assembly_return_high", 22280.0, "p2_assembly_gallery", 22160.0],
		["p2_flank_vertical_deck", 26100.0, "p2_flank_vertical_upper", 26250.0],
		["p2_flank_vertical_upper", 26250.0, "p2_flank_vertical_deck", 26100.0, false],
		["part_three_factory_floor", 29980.0, "p3_climb_entry", 30060.0],
		["p3_climb_entry", 30060.0, "p3_flank_vertical_lower", 30180.0],
		["p3_flank_vertical_lower", 30180.0, "p3_climb_high", 30300.0],
		["p3_climb_high", 30300.0, "p3_transfer_gallery", 30400.0],
		["p3_transfer_gallery", 30390.0, "p3_flank_vertical_upper", 30500.0],
		["p3_flank_vertical_upper", 30500.0, "p3_transfer_gallery", 30390.0],
		["p3_flank_vertical_upper", 30600.0, "p3_ammo_return", 30740.0],
		["p3_ammo_return", 30740.0, "p3_flank_vertical_upper", 30600.0],
		["p3_factory_continuation", 31450.0, "p3_descent_low", 31360.0],
		["p3_descent_low", 31360.0, "p3_descent_mid", 31240.0],
		["p3_descent_mid", 31240.0, "p3_descent_high", 31120.0],
		["p3_descent_high", 31120.0, "p3_transfer_gallery", 31010.0],
		["p3_factory_continuation", 37530.0, "coalition_lower", 37640.0],
		["coalition_lower", 38100.0, "coalition_upper", 38230.0],
		["coalition_upper", 38230.0, "coalition_lower", 38100.0],
	]
	for leg: Array in legs:
		var source := level.get_node("Generated/Platforms/" + String(leg[0])) as DebugPlatform
		var target := level.get_node("Generated/Platforms/" + String(leg[2])) as DebugPlatform
		assert_bool(target.is_rule_enabled()).is_true()
		var start_y := source.position.y - source.size.y * 0.5 + source.collision_surface_depth - WorldPropPlacement.BALL_ORIGIN_TO_FLOOR
		var end_y := target.position.y - target.size.y * 0.5 + target.collision_surface_depth - WorldPropPlacement.BALL_ORIGIN_TO_FLOOR
		player.reset_at(Vector2(float(leg[1]), start_y))
		# Descending beneath an overhead walkway uses a walk-off, not a jump
		# into that walkway's underside. Both are baseline movement routes.
		player.velocity.y = -profile.jump_velocity if leg.size() < 5 or bool(leg[4]) else 0.0
		var landed := false
		for frame: int in 110:
			var dx := float(leg[3]) - player.position.x
			player.velocity.x = clampf(dx * 10.0, -profile.run_speed, profile.run_speed)
			player.velocity.y = MovementMath.vertical_velocity(player.velocity.y, profile, 1.0 / 60.0)
			player.move_and_slide()
			await get_tree().physics_frame
			if player.is_on_floor() and absf(player.position.y - end_y) < 3.0 and absf(dx) < 25.0:
				landed = true
				break
		assert_bool(landed).override_failure_message("Base route: %s -> %s" % [leg[0], leg[2]]).is_true()
