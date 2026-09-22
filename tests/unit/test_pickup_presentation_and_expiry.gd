extends GdUnitTestSuite


func _level() -> LevelBuilder:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	return level


func _release_first(economy: WorkshopEconomy) -> String:
	var observer := economy.builder.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver
	var id := "loot_" + String(observer._actors[0].stable_id)
	observer._actors[0].conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	observer._actors[0].conflict_state.neutralize()
	return id


func after_test() -> void:
	get_tree().paused = false


func test_all_static_pickups_have_aura_but_never_expire() -> void:
	var level := _level()
	for pickup: DebugPickup in level.get_node("Generated/Resources").get_children():
		assert_bool(pickup.presentation.is_valid()).is_true()
		assert_object(pickup.get_node_or_null("CollectibleAura")).is_not_null()
		if pickup.lifetime_seconds > 0.0:
			continue
		pickup.advance_lifetime(10000.0)
		assert_bool(pickup.is_queued_for_deletion()).is_false()
		assert_bool(pickup.is_expiring()).is_false()
		pickup._visual_time = 0.0
		pickup._update_collectible_visual()
		var alpha := pickup._aura.modulate.a
		pickup._visual_time = pickup.presentation.pulse_seconds * 0.25
		pickup._update_collectible_visual()
		assert_float(pickup._aura.modulate.a).is_greater(alpha)
		pickup.set_available(false)
		assert_bool(pickup.visible).is_false()
		assert_bool(pickup.is_processing()).is_false()


func test_drop_clock_starts_on_release_pauses_and_warns_before_freeing() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var id := "loot_" + String((level.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver)._actors[0].stable_id)
	var drop := economy.loot.drops[id] as DebugPickup
	drop.advance_lifetime(1000.0)
	assert_float(drop.remaining_seconds).is_equal(90.0)
	_release_first(economy)
	economy.open_shop()
	drop.advance_lifetime(1000.0)
	assert_float(drop.remaining_seconds).is_equal(90.0)
	economy.close_shop()
	drop.advance_lifetime(81.0)
	assert_bool(drop.is_expiring()).is_true()
	assert_float(drop.remaining_seconds).is_equal(9.0)
	drop._visual_time = 0.0
	drop._update_collectible_visual()
	assert_float(drop._sprite.modulate.a).is_equal(1.0)
	drop._visual_time = 0.3
	drop._update_collectible_visual()
	assert_float(drop._sprite.modulate.a).is_less(0.5)
	var rewards_before := level._collected_reward_ids.size()
	var sats_before := level._player.inventory.satoshis
	drop.advance_lifetime(9.0)
	assert_bool(economy.loot.drops.has(id)).is_false()
	assert_bool(economy.loot.capture()[id].expired).is_true()
	assert_bool(drop.is_queued_for_deletion()).is_true()
	drop._on_body_entered(level._player)
	assert_int(level._player.inventory.count("social_contract")).is_equal(0)
	assert_int(level._collected_reward_ids.size()).is_equal(rewards_before)
	assert_int(level._player.inventory.satoshis).is_equal(sats_before)
	await get_tree().process_frame
	assert_bool(is_instance_valid(drop)).is_false()
	economy.loot.release(id)
	assert_bool(economy.loot.drops.has(id)).is_false()


func test_checkpoint_restores_remaining_time_or_expiry_without_resurrecting() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var id := _release_first(economy)
	var drop := economy.loot.drops[id] as DebugPickup
	drop.advance_lifetime(85.0)
	level.activate_checkpoint(&"warning", Vector2(500, 600))
	drop.advance_lifetime(6.0)
	await get_tree().process_frame
	assert_bool(is_instance_valid(drop)).is_false()
	level.retry_from_checkpoint()
	drop = economy.loot.drops[id] as DebugPickup
	assert_float(drop.remaining_seconds).is_equal(5.0)
	assert_bool(drop.is_expiring()).is_true()
	assert_bool(drop.visible).is_true()
	drop.advance_lifetime(5.0)
	level.activate_checkpoint(&"expired", Vector2(500, 600))
	level.retry_from_checkpoint()
	assert_bool(economy.loot.drops.has(id)).is_false()
	assert_bool(economy.loot.capture()[id].expired).is_true()
	economy.loot.release(id)
	assert_bool(economy.loot.drops.has(id)).is_false()


func test_collection_frees_drop_and_retry_can_recreate_uncollected_snapshot() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var id := _release_first(economy)
	var drop := economy.loot.drops[id] as DebugPickup
	level.activate_checkpoint(&"before_collection", Vector2(500, 600))
	drop.advance_drop(drop.presentation.drop_arc_seconds)
	drop._on_body_entered(level._player)
	assert_int(level._player.inventory.count("social_contract")).is_equal(20)
	assert_bool(economy.loot.drops.has(id)).is_false()
	await get_tree().process_frame
	assert_bool(is_instance_valid(drop)).is_false()
	level.retry_from_checkpoint()
	drop = economy.loot.drops[id] as DebugPickup
	assert_float(drop.remaining_seconds).is_equal(90.0)
	assert_int(level._player.inventory.count("social_contract")).is_equal(0)
	drop.advance_drop(drop.presentation.drop_arc_seconds)
	drop._on_body_entered(level._player)
	level.activate_checkpoint(&"after_collection", Vector2(500, 600))
	level.retry_from_checkpoint()
	economy.loot.release(id)
	assert_bool(economy.loot.drops.has(id)).is_false()
	assert_int(level._player.inventory.count("social_contract")).is_equal(20)


func test_legacy_drop_snapshot_gains_full_lifetime_and_invalid_config_is_rejected() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var id := _release_first(economy)
	economy.loot.restore({id: {"available": true, "x": 720.0, "y": 640.0}})
	assert_float((economy.loot.drops[id] as DebugPickup).remaining_seconds).is_equal(90.0)
	var profile := economy.profile.duplicate(true) as RunEconomyDefinition
	profile.drop_warning_seconds = profile.drop_lifetime_seconds
	assert_bool(profile.validation_errors(level.loaded_spec).is_empty()).is_false()
	profile.drop_warning_seconds = 10.0
	profile.actor_drop_rewards["enemy_occupancy_enforcer"] = {"items": {"production_key": 1}}
	assert_bool(profile.validation_errors(level.loaded_spec).is_empty()).is_false()


func test_collection_shape_follows_visible_art_not_aura_or_transparent_padding() -> void:
	var level := _level()
	for pickup: DebugPickup in level.get_node("Generated/Resources").get_children():
		var bounds := pickup.visible_art_rect()
		var shape := pickup._collection_shape.shape as RectangleShape2D
		assert_vector(pickup._collection_shape.position).is_equal(bounds.get_center())
		assert_vector(shape.size).is_equal((bounds.size + Vector2.ONE * 12.0).max(Vector2.ONE * 20.0))


func test_lift_collects_ammo_by_riding_without_jump_and_key_stays_on_upper_route() -> void:
	var level := _level()
	var lift := level.get_node("Generated/Platforms/platform_restored_lift") as DebugPlatform
	var pickup := level.get_node("Generated/Resources/pickup_lift_ammo") as DebugPickup
	var key := level.get_node("Generated/Resources/pickup_production_key") as DebugPickup
	lift.set_rule_enabled(true)
	var start_surface := lift.position.y - lift.size.y * 0.5 + lift.collision_surface_depth
	level._player.reset_at(Vector2(pickup.position.x, start_surface - 25.0))
	var ammunition_before := level._player.inventory.count("heavy_ammo")
	for frame: int in 360:
		await get_tree().physics_frame
		if pickup.is_collected():
			break
	assert_bool(pickup.is_collected()).is_true()
	assert_bool(key.is_collected()).is_false()
	assert_int(level._player.inventory.count("heavy_ammo")).is_equal(ammunition_before + 12)


func test_enabling_pickup_around_overlapping_player_collects_without_reentry() -> void:
	var level := _level()
	var pickup := level.get_node("Generated/Resources/pickup_lift_ammo") as DebugPickup
	level._player.set_physics_process(false)
	pickup.set_available(false)
	level._player.position = pickup.position + Vector2(0, 45)
	for frame: int in 3:
		await get_tree().physics_frame
	assert_bool(pickup.is_collected()).is_false()
	pickup.set_available(true)
	for frame: int in 4:
		await get_tree().physics_frame
	assert_bool(pickup.is_collected()).is_true()


func test_drop_launch_rises_curves_and_lands_near_actor_without_rescaling() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var id := _release_first(economy)
	var drop := economy.loot.drops[id] as DebugPickup
	var actor := economy.loot.actors[id] as CombatTarget
	var origin := actor.position
	var landing := economy.loot._drop_position(id)
	var art_scale := drop._sprite.scale
	assert_vector(drop.position).is_equal(origin)
	drop._on_body_entered(level._player)
	assert_bool(drop.is_collected()).is_false()
	assert_int(level._player.inventory.count("social_contract")).is_equal(0)
	drop.advance_drop(drop.presentation.drop_arc_seconds * 0.5)
	var apex := drop.position
	assert_float(apex.y).is_less(origin.y - 40.0)
	assert_float(apex.x).is_equal_approx((origin.x + landing.x) * 0.5, 0.01)
	assert_bool(drop._aura.is_visible_in_tree()).is_true()
	assert_vector(drop._sprite.scale).is_equal(art_scale)
	drop.advance_drop(drop.presentation.drop_arc_seconds * 0.5)
	assert_vector(drop.position).is_equal(landing)
	assert_float(absf(drop.position.x - origin.x)).is_less_equal(economy.profile.loot_horizontal_offset)
	assert_bool(drop._drop_active).is_false()
	drop.advance_drop(10.0)
	assert_vector(drop.position).is_equal(landing)
	drop._on_body_entered(level._player)
	assert_int(level._player.inventory.count("social_contract")).is_equal(20)


func test_drop_arc_pauses_and_checkpoint_resumes_json_roundtrip_without_relaunch() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var id := _release_first(economy)
	var drop := economy.loot.drops[id] as DebugPickup
	drop.advance_drop(0.15)
	var before := drop.position
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(economy.loot.capture()))
	economy.open_shop()
	drop.advance_drop(20.0)
	assert_vector(drop.position).is_equal(before)
	economy.close_shop()
	drop.advance_drop(0.2)
	economy.loot.restore(snapshot)
	assert_vector(drop.position).is_equal(before)
	assert_float(drop._drop_elapsed).is_equal(0.15)
	economy.loot.release(id)
	assert_float(drop._drop_elapsed).is_equal(0.15)
	drop.advance_drop(0.15)
	assert_float(drop.position.y).is_less(before.y)
	assert_int(level._player.inventory.count("social_contract")).is_equal(0)
	drop.advance_drop(1.0)
	assert_bool(drop._drop_active).is_false()
	assert_vector(drop.position).is_equal(economy.loot._drop_position(id))
	economy.loot.restore({id: {"available": true, "x": 720.0, "y": 640.0}})
	assert_bool(drop._drop_active).is_false()
	drop.advance_drop(1.0)
	assert_vector(drop.position).is_equal(Vector2(720, 640))


func test_drop_collects_overlapping_player_after_launch_delay_without_reentry() -> void:
	var level := _level()
	level._player.set_physics_process(false)
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var id := _release_first(economy)
	var drop := economy.loot.drops[id] as DebugPickup
	for frame: int in 80:
		if not is_instance_valid(drop) or drop.is_queued_for_deletion():
			break
		level._player.global_position = drop.global_position
		await get_tree().physics_frame
	assert_int(level._player.inventory.count("social_contract")).is_equal(20)
	assert_bool(economy.loot.drops.has(id)).is_false()


func test_invalid_arc_profile_is_rejected_and_static_pickups_do_not_launch() -> void:
	var level := _level()
	var pickup := level.get_node("Generated/Resources/pickup_lift_ammo") as DebugPickup
	var origin := pickup.position
	pickup.advance_drop(10.0)
	assert_vector(pickup.position).is_equal(origin)
	assert_bool(pickup._drop_active).is_false()
	var profile := pickup.presentation.duplicate() as PickupPresentationProfile
	profile.drop_arc_seconds = 0.0
	assert_bool(profile.is_valid()).is_false()
	profile.drop_arc_seconds = 0.6
	profile.drop_collection_delay = 0.7
	assert_bool(profile.is_valid()).is_false()
