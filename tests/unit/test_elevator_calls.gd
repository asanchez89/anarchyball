extends GdUnitTestSuite


func test_every_authored_lift_has_calls_on_both_sides_of_travel_midpoint() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	for platform: Dictionary in spec.data.platforms:
		var motion := float(platform.get("motion_distance_y", 0.0))
		if is_zero_approx(motion):
			continue
		var midpoint := float(platform.y) + motion * 0.5
		var upper := false
		var lower := false
		for station: Dictionary in spec.data.rule_objects:
			if not bool(station.get("call_only", false)) or not (station.target_platform_ids as Array).has(platform.id):
				continue
			upper = upper or float(station.y) < midpoint
			lower = lower or float(station.y) > midpoint
			assert_bool((station.get("requires", []) as Array).is_empty()).is_false()
		assert_bool(upper and lower).override_failure_message("Missing two-stop recall: " + String(platform.id)).is_true()


func test_first_lift_can_be_boarded_ridden_and_collect_its_real_rewards() -> void:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	var player := level._player
	player.set_physics_process(false)
	for node: Node in level.find_children("*", "", true, false):
		if node is CombatTarget:
			node.set_process(false)
		elif node is CeasefireChallenge:
			node.set_physics_process(false)
	var lift := level.get_node("Generated/Platforms/platform_restored_lift") as DebugPlatform
	var ammunition := player.inventory.count("heavy_ammo")
	# Service payment has separate economy tests; here only enable the result
	# and traverse it. Pickups must come from overlap, never direct callbacks.
	lift.set_rule_enabled(true)
	player.reset_at(Vector2(4040, 658))
	await get_tree().physics_frame
	player.velocity.y = -player.movement_profile.jump_velocity
	var boarded := false
	var reached_top := false
	for frame: int in 330:
		player.velocity.y = MovementMath.vertical_velocity(player.velocity.y, player.movement_profile, 1.0 / 60.0)
		player.move_and_slide()
		await get_tree().physics_frame
		boarded = boarded or (player.is_on_floor() and player.position.y < 600.0)
		if boarded and player.is_on_floor() and player.position.y < 362.0:
			reached_top = true
			break
	assert_bool(boarded).override_failure_message("Cannot board first lift with base jump").is_true()
	assert_bool(reached_top).override_failure_message("Lift does not carry player to reward height").is_true()
	player.velocity.y = -player.movement_profile.jump_velocity
	for frame: int in 70:
		player.velocity.x = move_toward(player.velocity.x, clampf((4150.0 - player.position.x) * 10.0, -player.movement_profile.run_speed, player.movement_profile.run_speed), player.movement_profile.air_acceleration * player.movement_profile.air_control / 60.0)
		player.velocity.y = MovementMath.vertical_velocity(player.velocity.y, player.movement_profile, 1.0 / 60.0)
		player.move_and_slide()
		await get_tree().physics_frame
	assert_int(player.inventory.count("heavy_ammo")).is_equal(ammunition + 12)
	assert_int(player.inventory.count("production_key")).is_equal(1)
	for frame: int in 100:
		player.velocity.x = clampf((3880.0 - player.position.x) * 10.0, -player.movement_profile.run_speed, player.movement_profile.run_speed)
		player.velocity.y = MovementMath.vertical_velocity(player.velocity.y, player.movement_profile, 1.0 / 60.0)
		player.move_and_slide()
		await get_tree().physics_frame
		if player.is_on_floor() and absf(player.position.x - 3880.0) < 25.0:
			break
	assert_float(absf(player.position.x - 3880.0)).is_less(25.0)
	assert_bool(player.is_on_floor()).is_true()


func test_runtime_call_stations_stay_on_their_landings_and_choose_correct_stop() -> void:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	await get_tree().physics_frame
	for pair: Array in [
		["call_production_lift", "call_production_lift_upper", "production_upper_call_landing"],
		["call_storage_lift", "call_storage_lift_upper", "storage_upper_call_landing"],
		["call_dispatch_lift", "call_dispatch_lift_upper", "dispatch_upper_call_landing"],
		["call_crew_lift_lower", "call_crew_lift_upper", "crew_upper_call_landing"],
	]:
		var lower := level.get_node("Generated/RuleObjects/" + String(pair[0])) as RuleStateObject
		var upper := level.get_node("Generated/RuleObjects/" + String(pair[1])) as RuleStateObject
		var landing := level.get_node("Generated/Platforms/" + String(pair[2])) as DebugPlatform
		var lift := upper.target_platforms[0]
		var midpoint := lift._motion_origin_y + lift.motion_distance_y() * 0.5
		assert_float(upper.position.y).override_failure_message("Upper call moved downstairs: " + String(pair[1])).is_less(midpoint)
		assert_float(lower.position.y).is_greater(midpoint)
		assert_bool(landing.is_rule_enabled()).override_failure_message("Upper call has no active support: " + String(pair[1])).is_true()
		var floor_y := landing.position.y - landing.size.y * 0.5 + landing.collision_surface_depth
		assert_float(upper.position.y).is_equal(floor_y)
		for gate: Node in level.get_node("Generated/Gates").get_children():
			assert_float(absf((gate as Node2D).position.x - upper.position.x)).override_failure_message("Upper terminal overlaps gate: " + String(pair[1])).is_greater_equal(90.0)
		assert_bool(upper.interact()).is_false()
		for prerequisite: RuleStateObject in upper.prerequisites:
			prerequisite.transition_to(RuleStateObject.State.OCCUPIED, false)
		lift.set_physics_process(false)
		assert_bool(upper.interact()).is_true()
		assert_float(lift._motion_direction).is_equal(-1.0)
		assert_bool(lower.interact()).is_true()
		assert_float(lift._motion_direction).is_equal(1.0)


func test_calls_travel_physically_to_either_stop_without_teleporting() -> void:
	var lift := auto_free(DebugPlatform.new()) as DebugPlatform
	lift.position = Vector2(100, 560)
	lift.configure_motion(-210, 70)
	add_child(lift)
	lift.set_physics_process(false)
	lift.sync_to_physics = false
	assert_str(lift.call_caption(330)).is_equal("UP")
	assert_str(lift.call_caption(630)).is_equal("DOWN")
	lift.call_to_nearest_stop(330)
	assert_float(lift.position.y).is_equal(560.0)
	lift._physics_process(1.0)
	assert_float(lift.position.y).is_equal(490.0)
	lift._physics_process(2.0)
	assert_float(lift.position.y).is_equal(350.0)
	lift.call_to_nearest_stop(630)
	assert_float(lift.position.y).is_equal(350.0)
	lift._physics_process(3.0)
	assert_float(lift.position.y).is_equal(560.0)
	lift.set_rule_enabled(false)
	lift.call_to_nearest_stop(330)
	lift._physics_process(3.0)
	assert_float(lift.position.y).is_equal(560.0)
