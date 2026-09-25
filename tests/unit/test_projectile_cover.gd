extends GdUnitTestSuite


func _deck(at: Vector2, dimensions: Vector2) -> DebugPlatform:
	var deck := auto_free(DebugPlatform.new()) as DebugPlatform
	deck.sync_to_physics = false
	deck.position = at
	deck.size = dimensions
	add_child(deck)
	return deck


func test_thin_decks_pass_downward_shots_only_for_both_projectiles() -> void:
	_deck(Vector2(200, 100), Vector2(100, 24))
	await get_tree().physics_frame
	await get_tree().physics_frame
	for path: String in ["res://src/combat/sandbox/aim_probe.tscn", "res://src/combat/sandbox/hostile_bolt.tscn"]:
		for sample: Array in [[Vector2(200, 50), Vector2.DOWN, false], [Vector2(200, 150), Vector2.UP, true], [Vector2(100, 100), Vector2.RIGHT, true], [Vector2(100, 90), Vector2(1, 0.1).normalized(), true]]:
			var shot := auto_free(load(path).instantiate()) as Area2D
			add_child(shot)
			shot.set_physics_process(false)
			shot.global_position = sample[0]
			shot.set("direction", sample[1])
			shot.set("speed", 3000.0)
			shot.call("_physics_process", 0.1)
			assert_bool(shot.is_queued_for_deletion()).override_failure_message("%s at %s" % [path, sample[0]]).is_equal(sample[2])


func test_slow_descent_continues_inside_deck_but_stops_at_solid_below() -> void:
	_deck(Vector2(200, 100), Vector2(100, 24))
	_deck(Vector2(200, 200), Vector2(100, 80))
	await get_tree().physics_frame
	await get_tree().physics_frame
	for path: String in ["res://src/combat/sandbox/aim_probe.tscn", "res://src/combat/sandbox/hostile_bolt.tscn"]:
		var shot := auto_free(load(path).instantiate()) as Area2D
		add_child(shot)
		shot.set_physics_process(false)
		shot.global_position = Vector2(200, 86)
		shot.set("direction", Vector2.DOWN)
		shot.set("speed", 360.0)
		for frame: int in 10:
			shot.call("_physics_process", 0.01)
			assert_bool(shot.is_queued_for_deletion()).is_false()
		assert_float(shot.global_position.y).is_greater(112.0)
		shot.call("_physics_process", 1.0)
		assert_bool(shot.is_queued_for_deletion()).is_true()
	# One long sweep must also find the solid after excluding the thin deck.
	assert_bool(ProjectileTerrain.obstruction(get_viewport().world_2d, Vector2(200, 50), Vector2(200, 300)).is_empty()).is_false()


func test_downward_muzzles_can_cross_the_supporting_deck() -> void:
	_deck(Vector2(200, 100), Vector2(200, 24))
	var actor := auto_free(load("res://src/debug/combat_target.tscn").instantiate()) as CombatTarget
	add_child(actor)
	actor.set_process(false)
	actor.position = Vector2(200, 70)
	await get_tree().physics_frame
	await get_tree().physics_frame
	actor._launch_bolt_direction(Vector2.DOWN)
	var shot := get_child(get_child_count() - 1) as HostileBolt
	shot.set_physics_process(false)
	assert_float(shot.position.y).is_equal(104.0)
	shot.call("_physics_process", 0.05)
	assert_bool(shot.is_queued_for_deletion()).is_false()
	shot.queue_free()


func test_muzzles_cannot_spawn_projectiles_behind_a_near_wall() -> void:
	var wall := auto_free(StaticBody2D.new()) as StaticBody2D
	wall.position = Vector2(125, 100)
	wall.collision_layer = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2, 200)
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)
	var player := auto_free(load("res://src/actors/player/player.tscn").instantiate()) as PlayerController
	add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(100, 100)
	var launcher := player.get_node("ProbeLauncher") as SandboxProbeLauncher
	launcher.set_physics_process(false)
	launcher._last_aim_direction = Vector2.RIGHT
	var enemy := auto_free(load("res://src/debug/combat_target.tscn").instantiate()) as CombatTarget
	add_child(enemy)
	enemy.set_process(false)
	enemy.position = Vector2(100, 100)
	enemy.hostile_bolt_scene = load("res://src/combat/sandbox/hostile_bolt.tscn")
	await get_tree().physics_frame
	launcher._fire_probe()
	enemy._launch_bolt_direction(Vector2.RIGHT)
	var count := 0
	for projectile: Node in get_children():
		if not (projectile is AimProbe or projectile is HostileBolt):
			continue
		count += 1
		projectile.set_physics_process(false)
		assert_float((projectile as Node2D).global_position.x).is_less(124.0)
		projectile.call("_physics_process", 0.1)
		assert_bool(projectile.is_queued_for_deletion()).is_true()
	assert_int(count).is_equal(2)


func test_both_projectiles_stop_at_thin_terrain_even_when_crossed_in_one_step() -> void:
	var wall := auto_free(StaticBody2D.new()) as StaticBody2D
	wall.position = Vector2(200, 100)
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2, 200)
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)
	await get_tree().physics_frame
	for scene_path: String in ["res://src/combat/sandbox/aim_probe.tscn", "res://src/combat/sandbox/hostile_bolt.tscn"]:
		for origin: Vector2 in [Vector2(100, 100), Vector2(200, 100), Vector2(100, -30)]:
			var projectile := auto_free(load(scene_path).instantiate()) as Area2D
			add_child(projectile)
			projectile.set_physics_process(false)
			projectile.global_position = origin
			projectile.set("direction", Vector2.RIGHT)
			projectile.set("speed", 3000.0)
			projectile.call("_physics_process", 0.1)
			if origin.y > 0.0:
				assert_bool(projectile.is_queued_for_deletion()).override_failure_message(scene_path + ": passed through cover").is_true()
			else:
				assert_bool(projectile.is_queued_for_deletion()).is_false()
				assert_float(projectile.global_position.x).is_equal(400.0)
