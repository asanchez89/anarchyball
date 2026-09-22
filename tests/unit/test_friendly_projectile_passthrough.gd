extends GdUnitTestSuite


func test_all_mutualist_archetypes_pass_both_weapon_shots_to_aggressor() -> void:
	for archetype_id: String in ["npc_mutualist_operator", "npc_mutualist_mechanic", "npc_mutualist_claimant"]:
		for damage: float in [5.0, 14.0]:
			var world := Node2D.new()
			add_child(world)
			var definition := load("res://data/content/enemies/" + archetype_id + ".tres") as EnemyArchetype
			var friendly := load("res://src/debug/combat_target.tscn").instantiate() as CombatTarget
			friendly.apply_archetype(definition)
			friendly.position = Vector2(100, -1000)
			world.add_child(friendly)
			friendly.set_process(false)
			var enemy := load("res://src/debug/combat_target.tscn").instantiate() as CombatTarget
			enemy.position = Vector2(260, -1000)
			world.add_child(enemy)
			enemy.set_process(false)
			enemy.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
			var source := CombatIdentityComponent.new()
			source.authority = CombatIdentityComponent.Authority.PLAYER
			source.stable_id = &"player"
			world.add_child(source)
			var impacts: Array[TargetPermission] = []
			friendly.receiver.effect_blocked.connect(func(permission: TargetPermission) -> void: impacts.append(permission))
			var friendly_before := friendly.resolve.current_resolve
			var enemy_before := enemy.resolve.current_resolve
			assert_bool(friendly.get_collision_layer_value(4)).is_false()
			if not definition.dialogue_lines.is_empty():
				assert_object(friendly.get_node_or_null("NpcDialogue")).is_not_null()
			assert_bool(TargetValidity.evaluate(source, friendly.receiver, EffectContext.offensive()).allowed).is_false()
			var projectile := load("res://src/combat/sandbox/aim_probe.tscn").instantiate() as AimProbe
			projectile.position = Vector2(0, -1000)
			projectile.effect_amount = damage
			projectile.configure(Vector2.RIGHT, source, EffectContext.offensive())
			world.add_child(projectile)
			for frame: int in 45:
				await get_tree().physics_frame
				if not is_instance_valid(projectile):
					break
			assert_float(friendly.resolve.current_resolve).is_equal(friendly_before)
			assert_array(impacts).is_empty()
			assert_float(enemy.resolve.current_resolve).is_equal(enemy_before - damage)
			assert_bool(is_instance_valid(projectile)).is_false()
			friendly.restore_runtime_state(friendly.capture_runtime_state())
			assert_bool(friendly.get_collision_layer_value(4)).is_false()
			world.queue_free()
			await get_tree().process_frame
