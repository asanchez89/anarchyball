extends GdUnitTestSuite
## Navigation audit, not a combat playthrough: gates are pre-opened and AI is
## disabled. Each test places the player only once, then traverses both ways.


func _navigation_level() -> LevelBuilder:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	level._player.set_physics_process(false)
	for node: Node in level.find_children("*", "", true, false):
		if node is CombatTarget:
			node.set_process(false)
		elif node is CeasefireChallenge:
			node.set_physics_process(false)
		elif node is AccessGate:
			node.restore_open(true)
	return level


func _walk_route(level: LevelBuilder, points: Array[Vector2]) -> bool:
	var player := level._player
	var profile := player.movement_profile
	for index: int in range(1, points.size()):
		var target := points[index]
		var previous := points[index - 1]
		var cover_gap := (minf(previous.x, target.x) == 22880.0 and maxf(previous.x, target.x) == 23020.0) or (minf(previous.x, target.x) == 17560.0 and maxf(previous.x, target.x) == 17720.0)
		var jump := target.y < previous.y - 12.0 or cover_gap
		if jump:
			player.velocity.y = -profile.jump_velocity
		# Every local ascent/descent must show its landing with the real camera.
		if absf(target.y - previous.y) > 12.0 or cover_gap:
			player.player_camera.force_update_scroll()
			var extent := player.get_viewport_rect().size / player.player_camera.zoom
			var visible := Rect2(player.player_camera.get_screen_center_position() - extent * 0.5, extent)
			assert_bool(visible.has_point(target)).override_failure_message("Blind landing: %s -> %s, view=%s" % [previous, target, visible]).is_true()
		var arrived := false
		var frames := int(ceil(absf(target.x - previous.x) / profile.run_speed * 60.0)) + 180
		for frame: int in frames:
			var axis := clampf((target.x - player.position.x) / 30.0, -1.0, 1.0)
			player.velocity.x = MovementMath.horizontal_velocity(player.velocity.x, axis, player.is_on_floor(), profile, 1.0 / 60.0)
			player.velocity.y = MovementMath.vertical_velocity(player.velocity.y, profile, 1.0 / 60.0)
			player.move_and_slide()
			await get_tree().physics_frame
			if player.is_on_floor() and absf(player.position.y - target.y) < 5.0 and absf(player.position.x - target.x) < 10.0:
				arrived = true
				break
		assert_bool(arrived).override_failure_message("Continuous leg %d: %s -> %s stopped at %s" % [index, previous, target, player.position]).is_true()
		if not arrived:
			return false
	return true


func _round_trip(points: Array[Vector2], resolved_ids: Array[String] = []) -> void:
	var level := _navigation_level()
	for id: String in resolved_ids:
		(level.get_node("Generated/EncounterObservers/" + id) as EncounterRuntimeObserver).restore_runtime_state({"resolved": true})
	await get_tree().physics_frame
	await get_tree().physics_frame
	level._player.reset_at(points[0])
	level._player.player_camera.reset_smoothing()
	if not await _walk_route(level, points):
		return
	points.reverse()
	assert_bool(await _walk_route(level, points)).is_true()


func test_part_one_depot_return_after_collective_resolution() -> void:
	await _round_trip([
		Vector2(7720, 433), Vector2(8190, 433), Vector2(8320, 508),
		Vector2(8440, 583),
	], ["encounter_depot_patrol"])


func test_part_one_dispatch_collective_return_after_resolution() -> void:
	await _round_trip([
		Vector2(13870, 433), Vector2(14370, 433), Vector2(14480, 508),
		Vector2(14580, 583),
	], ["encounter_dispatch_ancom"])


func test_part_one_dispatch_descent_returns_without_power() -> void:
	await _round_trip([
		Vector2(15710, 283), Vector2(15810, 358), Vector2(15910, 433),
		Vector2(16010, 508), Vector2(16110, 583), Vector2(16160, 583),
		Vector2(16250, 638),
	])


func test_part_one_crew_exit_has_a_staged_return() -> void:
	await _round_trip([
		Vector2(19130, 358), Vector2(19250, 448), Vector2(19400, 448),
		Vector2(19500, 538), Vector2(19600, 538), Vector2(19720, 578),
		Vector2(19830, 638),
	])


func test_dispatch_return_also_works_with_upper_service_bridge_enabled() -> void:
	var level := _navigation_level()
	(level.get_node("Generated/Platforms/dispatch_exit_bridge") as DebugPlatform).set_rule_enabled(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	level._player.reset_at(Vector2(15710, 283))
	level._player.player_camera.reset_smoothing()
	if not await _walk_route(level, [Vector2(15710, 283), Vector2(15930, 283), Vector2(16020, 508), Vector2(16110, 583), Vector2(16250, 638)]):
		return
	assert_bool(await _walk_route(level, [Vector2(16250, 638), Vector2(16160, 583), Vector2(16110, 583), Vector2(16010, 508), Vector2(15910, 433), Vector2(15810, 358), Vector2(15710, 283)])).is_true()


func test_dispatch_stairs_do_not_bypass_the_unresolved_gate() -> void:
	var level := _navigation_level()
	var gate := level.get_node("Generated/Gates/gate_dispatch") as AccessGate
	gate.restore_open(false)
	await get_tree().physics_frame
	level._player.reset_at(Vector2(16010, 508))
	for frame: int in 70:
		level._player.velocity = Vector2(300, 100)
		level._player.move_and_slide()
		await get_tree().physics_frame
	assert_float(level._player.position.x).is_less(gate.position.x)
	gate.restore_open(true)
	await get_tree().physics_frame
	assert_bool(await _walk_route(level, [level._player.position, Vector2(16150, 583)])).is_true()


func test_part_one_continuous_route_and_lower_crew_return() -> void:
	var level := _navigation_level()
	for id: String in ["encounter_depot_patrol", "encounter_dispatch_ancom"]:
		(level.get_node("Generated/EncounterObservers/" + id) as EncounterRuntimeObserver).restore_runtime_state({"resolved": true})
	await get_tree().physics_frame
	await get_tree().physics_frame
	var points: Array[Vector2] = [
		Vector2(150, 658), Vector2(1340, 658), Vector2(1460, 578), Vector2(1540, 578), Vector2(1640, 658),
		Vector2(2600, 658), Vector2(2720, 578), Vector2(2920, 578), Vector2(3040, 658),
		Vector2(4240, 658), Vector2(4360, 583), Vector2(4520, 583), Vector2(4640, 508),
		Vector2(4760, 433), Vector2(4880, 358), Vector2(5280, 358), Vector2(5400, 433),
		Vector2(5600, 433), Vector2(5720, 508), Vector2(5900, 508), Vector2(6020, 583),
		Vector2(6120, 583), Vector2(6240, 658), Vector2(6780, 658), Vector2(6900, 583),
		Vector2(7040, 583), Vector2(7160, 508), Vector2(7340, 508), Vector2(7460, 433),
		Vector2(7720, 433), Vector2(8190, 433), Vector2(8320, 508), Vector2(8440, 583),
		Vector2(8480, 583), Vector2(8600, 508), Vector2(8840, 508), Vector2(8960, 583), Vector2(9100, 583),
		Vector2(9220, 658), Vector2(9660, 658), Vector2(9780, 583), Vector2(9920, 583),
		Vector2(10030, 508), Vector2(10160, 508), Vector2(10270, 418), Vector2(10400, 418),
		Vector2(10500, 358), Vector2(10940, 358), Vector2(11050, 448), Vector2(11200, 448),
		Vector2(11310, 538), Vector2(11460, 538), Vector2(11570, 628), Vector2(12350, 628),
		Vector2(12450, 658), Vector2(13000, 658), Vector2(13110, 583), Vector2(13260, 583),
		Vector2(13370, 508), Vector2(13520, 508), Vector2(13630, 433), Vector2(13870, 433),
		Vector2(14370, 433), Vector2(14480, 508), Vector2(14580, 583), Vector2(14710, 508),
		Vector2(14840, 508), Vector2(14950, 433), Vector2(15080, 433), Vector2(15190, 358),
		Vector2(15350, 358), Vector2(15460, 283), Vector2(15710, 283), Vector2(15810, 358),
		Vector2(15910, 433), Vector2(16010, 508), Vector2(16110, 583), Vector2(16160, 583),
		Vector2(16250, 638), Vector2(16650, 638), Vector2(16760, 563), Vector2(16910, 563),
		Vector2(17020, 488), Vector2(17170, 488), Vector2(17280, 413), Vector2(17560, 413),
		Vector2(17720, 423), Vector2(17870, 498), Vector2(18020, 578),
		Vector2(18160, 583), Vector2(18280, 583), Vector2(18400, 508), Vector2(18520, 508),
		Vector2(18640, 433), Vector2(18770, 433), Vector2(18880, 353), Vector2(19130, 358),
		Vector2(19250, 448), Vector2(19400, 448), Vector2(19500, 538), Vector2(19600, 538),
		Vector2(19720, 578), Vector2(19830, 638),
	]
	level._player.reset_at(points[0])
	level._player.player_camera.reset_smoothing()
	if not await _walk_route(level, points):
		return
	points.reverse()
	# Walk off the collective deck instead of requesting a drop through it.
	points.erase(Vector2(18770, 433))
	# The fixed cache ledge sits 15 px above the adjacent station. Return over
	# it, then walk off its left edge; do not run into its side from below.
	points[points.find(Vector2(15080, 433))] = Vector2(15080, 343)
	points.erase(Vector2(14950, 433))
	# The depot signal perch is also above the main stair: climb over it on
	# return, then leave its left edge rather than requesting a drop through.
	points[points.find(Vector2(7340, 508))] = Vector2(7340, 418)
	points.erase(Vector2(7160, 508))
	assert_bool(await _walk_route(level, points)).is_true()


func test_part_two_continuous_ascent_descent_and_return_with_base_acceleration() -> void:
	await _round_trip([
		Vector2(20000, 658), Vector2(21050, 658), Vector2(21160, 583),
		Vector2(21280, 508), Vector2(21400, 433), Vector2(21500, 358),
		Vector2(22160, 358), Vector2(22280, 433), Vector2(22400, 508),
		Vector2(22520, 583), Vector2(22620, 658), Vector2(22770, 658),
		Vector2(22880, 578), Vector2(23020, 578), Vector2(23400, 578),
		Vector2(23580, 658), Vector2(25810, 658), Vector2(25930, 578),
		Vector2(26120, 578), Vector2(26250, 498), Vector2(26410, 498),
		Vector2(26530, 498), Vector2(26630, 578), Vector2(26700, 578), Vector2(26810, 658),
		Vector2(28160, 658),
	])


func test_part_three_continuous_ascent_descent_and_return_with_base_acceleration() -> void:
	await _round_trip([
		Vector2(28250, 658), Vector2(29950, 658), Vector2(30060, 583),
		Vector2(30180, 508), Vector2(30300, 433), Vector2(30400, 358),
		Vector2(31010, 358), Vector2(31120, 433), Vector2(31240, 508),
		Vector2(31360, 583), Vector2(31470, 658), Vector2(33110, 658),
		Vector2(33230, 578), Vector2(33360, 578), Vector2(33500, 498),
		Vector2(33620, 498), Vector2(33750, 498), Vector2(33910, 498),
		Vector2(34000, 578), Vector2(34070, 578), Vector2(34180, 658),
		Vector2(34610, 658), Vector2(34730, 578), Vector2(34870, 578),
		Vector2(35010, 498), Vector2(35140, 498), Vector2(35250, 498),
		Vector2(35510, 498), Vector2(35610, 578), Vector2(35690, 578),
		Vector2(35800, 658), Vector2(37530, 658),
		Vector2(37640, 578), Vector2(38100, 578), Vector2(38230, 498),
		Vector2(38420, 498), Vector2(38520, 498), Vector2(38920, 498),
		Vector2(39020, 578), Vector2(39190, 658), Vector2(39930, 658),
	])
