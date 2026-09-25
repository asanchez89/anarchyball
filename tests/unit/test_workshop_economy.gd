extends GdUnitTestSuite


func _inventory() -> RunInventory:
	var inventory := RunInventory.new()
	inventory.configure(load("res://data/content/workshop_economy.tres") as RunEconomyDefinition)
	return inventory


func _level(extra_shops: Dictionary = {}) -> LevelBuilder:
	var scene := load("res://levels/world_0/w0_01_coalition_workshop.tscn") as PackedScene
	var level := auto_free(scene.instantiate()) as LevelBuilder
	level.start_in_menu = false
	if not extra_shops.is_empty():
		level.economy_profile = level.economy_profile.duplicate(true) as RunEconomyDefinition
		level.economy_profile.additional_shops = extra_shops
	add_child(level)
	assert_bool(level.last_validation.is_valid()).is_true()
	return level


func test_multiple_terminals_share_inventory_and_do_not_reset_purchases() -> void:
	var level := _level({"shop_part_two": Vector2(16800, 650), "shop_part_three": Vector2(19400, 650)})
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	assert_int(economy.shops.size()).is_equal(3)
	var inventory := level._player.inventory
	inventory.grant_once("test_funds", {}, 100)
	for terminal: RuleStateObject in economy.shops:
		assert_str(terminal._interaction_beacon.caption).is_equal("SHOP")
		assert_bool(terminal.interact()).is_true()
		assert_bool(level._player.inventory == inventory).is_true()
		assert_bool(economy.buy("heavy_pack")).is_true()
		economy.close_shop()
	assert_int(inventory.satoshis).is_equal(52)
	assert_int(inventory.count("heavy_ammo")).is_equal(40)
	assert_bool(get_tree().paused).is_false()


func test_additional_shop_validation_rejects_invalid_ids_positions_and_overlap() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	var profile := (load("res://data/content/workshop_economy.tres") as RunEconomyDefinition).duplicate(true) as RunEconomyDefinition
	for invalid: Dictionary in [{"bad/path": Vector2(100, 100)}, {"shop_two": Vector2(INF, 100)}, {"shop_two": "not_a_position"}, {"shop_two": profile.shop_position}]:
		profile.additional_shops = invalid
		assert_array(Array(profile.validation_errors(spec))).is_not_empty()
	profile.additional_shops = {"shop_two": Vector2(16800, 650), "shop_three": Vector2(19400, 650)}
	assert_array(Array(profile.validation_errors(spec))).is_empty()


func test_paid_maintenance_gate_requires_confirmation_and_restores_with_inventory() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var machine := level.get_node("Generated/RuleObjects/p2_maintenance_control") as RuleStateObject
	var gate := level.get_node("Generated/Gates/gate_p2_maintenance") as AccessGate
	var walkway := level.get_node("Generated/Platforms/p2_maintenance_walkway") as DebugPlatform
	assert_bool(walkway.is_rule_enabled()).is_false()
	assert_str(gate._label.text).contains("terminal ACTIVATE")
	assert_bool(gate.is_open()).is_false()
	assert_bool(machine.interact()).is_false()
	var description := economy._service_menu.find_child("ServiceDescription", true, false) as Label
	assert_str(description.text).contains(machine.machine_label)
	assert_bool(economy.confirm_service()).is_false()
	economy.close_service()
	(level.get_node("Generated/Resources/p2_maintenance_parts") as DebugPickup)._on_body_entered(level._player)
	assert_bool(machine.interact()).is_false()
	assert_bool(gate.is_open()).is_false()
	assert_bool(economy.confirm_service()).is_true()
	assert_bool(gate.is_open()).is_true()
	assert_bool(walkway.is_rule_enabled()).is_true()
	assert_int(level._player.inventory.count("service_parts")).is_equal(0)
	level.activate_checkpoint(&"paid_gate_test", Vector2(22800, 630))
	gate.restore_open(false)
	walkway.set_rule_enabled(false)
	level.retry_from_checkpoint()
	assert_bool(gate.is_open()).is_true()
	assert_bool(walkway.is_rule_enabled()).is_true()
	assert_int(level._player.inventory.count("service_parts")).is_equal(0)
	assert_bool(machine.interact()).is_false()
	assert_bool((level.get_node("Generated/EncounterObservers/p2_collective") as EncounterRuntimeObserver).is_resolved()).is_false()


func test_paid_walkway_connects_both_sides_and_collects_visible_ammo() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var machine := level.get_node("Generated/RuleObjects/p2_maintenance_control") as RuleStateObject
	var player := level._player
	player.set_physics_process(false)
	for node: Node in level.find_children("*", "", true, false):
		if node is CombatTarget:
			node.set_process(false)
		elif node is CeasefireChallenge:
			node.set_physics_process(false)
	(level.get_node("Generated/Resources/p2_maintenance_parts") as DebugPickup)._on_body_entered(player)
	machine.interact()
	assert_bool(economy.confirm_service()).is_true()
	await get_tree().physics_frame
	var before := player.inventory.count("light_ammo")
	var profile := player.movement_profile
	var legs: Array = [
		[Vector2(22530, 583), Vector2(22660, 503), true],
		[Vector2(22660, 503), Vector2(22530, 583), false],
		[Vector2(22750, 503), Vector2(22870, 578), false],
		[Vector2(22870, 578), Vector2(22740, 503), true],
	]
	for leg: Array in legs:
		player.reset_at(leg[0])
		player.velocity.y = -profile.jump_velocity if bool(leg[2]) else 0.0
		var target: Vector2 = leg[1]
		var landed := false
		for frame: int in 110:
			player.velocity.x = clampf((target.x - player.position.x) * 10.0, -profile.run_speed, profile.run_speed)
			player.velocity.y = MovementMath.vertical_velocity(player.velocity.y, profile, 1.0 / 60.0)
			player.move_and_slide()
			await get_tree().physics_frame
			if player.is_on_floor() and player.position.distance_to(target) < 12.0:
				landed = true
				break
		assert_bool(landed).override_failure_message("Paid walkway route %s -> %s stopped at %s" % [leg[0], target, player.position]).is_true()
	assert_int(player.inventory.count("light_ammo")).is_equal(before + 40)
	assert_bool((level.get_node("Generated/Gates/gate_p2_collective") as AccessGate).is_open()).is_false()
	level.activate_checkpoint(&"walkway_reward_test", player.position)
	level.retry_from_checkpoint()
	(level.get_node("Generated/Resources/p2_maintenance_ammo") as DebugPickup)._on_body_entered(player)
	assert_int(player.inventory.count("light_ammo")).is_equal(before + 40)


func test_upper_detour_supply_is_physical_and_checkpoint_does_not_duplicate_reward() -> void:
	var level := _level()
	var inventory := level._player.inventory
	var pickup := level.get_node("Generated/Resources/p3_ammo_return_supply") as DebugPickup
	var before_ammo := inventory.count("heavy_ammo")
	var before_parts := inventory.count("trade_parts")
	pickup._on_body_entered(level._player)
	assert_int(inventory.count("heavy_ammo")).is_equal(before_ammo + 12)
	assert_int(inventory.count("trade_parts")).is_equal(before_parts + 10)
	level.activate_checkpoint(&"detour_test", Vector2(30750, 170))
	level.retry_from_checkpoint()
	pickup._on_body_entered(level._player)
	assert_int(inventory.count("heavy_ammo")).is_equal(before_ammo + 12)
	assert_int(inventory.count("trade_parts")).is_equal(before_parts + 10)
	assert_bool((level.get_node("Generated/Gates/gate_p3_flank_vertical") as AccessGate).is_open()).is_false()


func test_service_station_spacing_and_shared_beacons() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var checkpoint := level.get_node("Generated/Checkpoints/checkpoint_supply_post") as CheckpointMarker
	assert_float(economy.shop.position.x - checkpoint.position.x).is_greater_equal(180.0)
	var shop_beacon := economy.shop.get_node("InteractionBeacon") as InteractionBeacon
	var checkpoint_beacon := checkpoint.get_node("InteractionBeacon") as InteractionBeacon
	assert_str(shop_beacon.caption).is_equal("SHOP")
	assert_str(checkpoint_beacon.caption).is_equal("CHECKPOINT")
	assert_bool(economy.shop._label.visible).is_false()
	var before := checkpoint._sprite.position
	checkpoint_beacon._process(0.5)
	assert_vector(checkpoint._sprite.position).is_equal(before)
	assert_object(checkpoint._sprite.material).is_not_null()
	economy.shop._on_body_entered(level._player)
	assert_bool(economy.shop._label.visible).is_true()
	economy.shop._on_body_exited(level._player)
	assert_bool(economy.shop._label.visible).is_false()


func test_functional_machine_signs_follow_capability_and_state() -> void:
	var level := _level()
	var power := level.get_node("Generated/RuleObjects/machine_production_feeder") as RuleStateObject
	var call := level.get_node("Generated/RuleObjects/call_production_lift") as RuleStateObject
	var panel := level.get_node("Generated/RuleObjects/control_production_transfer") as RuleStateObject
	assert_str(power._interaction_beacon.caption).is_equal("ACTIVATE")
	assert_bool(power._interaction_beacon.actionable).is_true()
	call._update_interaction_beacon()
	panel._update_interaction_beacon()
	assert_str(call._interaction_beacon.caption).is_equal("DOWN")
	assert_bool(call._interaction_beacon.actionable).is_false()
	assert_bool(panel._interaction_beacon.actionable).is_false()
	power.transition_to(RuleStateObject.State.OCCUPIED)
	assert_str(power._interaction_beacon.caption).is_equal("ACTIVE")
	assert_bool(power._interaction_beacon._halo.visible).is_false()
	call._update_interaction_beacon()
	panel._update_interaction_beacon()
	assert_bool(call._interaction_beacon.actionable).is_true()
	assert_bool(panel._interaction_beacon.actionable).is_true()
	assert_bool(call.interact()).is_true()
	assert_str(call._interaction_beacon.caption).is_equal("DOWN")
	power.restore_runtime_state({"state": "abandoned"})
	assert_str(power._interaction_beacon.caption).is_equal("ACTIVATE")
	assert_bool(power._interaction_beacon.actionable).is_true()
	for machine: Node in level.find_children("*", "RuleStateObject", true, false):
		assert_object(machine.get_node_or_null("InteractionBeacon")).is_not_null()
		assert_bool((machine as RuleStateObject)._label.visible).is_false()


func test_stack_rewards_are_once_only_and_protected_items_cannot_be_sold() -> void:
	var inventory := _inventory()
	assert_bool(inventory.grant_once("loot", {"trade_parts": 20, "production_key": 1}, 40)).is_true()
	assert_bool(inventory.grant_once("loot", {"trade_parts": 20}, 40)).is_false()
	assert_int(inventory.count("trade_parts")).is_equal(20)
	assert_bool(inventory.sell("production_key", 1)).is_false()
	assert_bool(inventory.sell("trade_parts", 10)).is_true()
	assert_int(inventory.satoshis).is_equal(60)
	assert_bool(inventory.buy("heavy_pack")).is_true()
	assert_int(inventory.count("heavy_ammo")).is_equal(24)
	assert_int(inventory.satoshis).is_equal(44)
	assert_bool(inventory.spend("light_ammo", -1)).is_false()
	assert_bool(inventory.buy("unknown")).is_false()


func test_shop_rejects_insufficient_funds_and_emergency_has_no_sale_value() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	assert_bool(economy.buy("light_pack")).is_false()
	assert_bool(economy.emergency_supply()).is_false()
	level._player.inventory.spend("light_ammo", 120)
	level._player.inventory.spend("heavy_ammo", 16)
	assert_bool(economy.emergency_supply()).is_true()
	assert_bool(economy.emergency_supply()).is_false()
	assert_bool(level._player.inventory.sell("light_ammo", 20)).is_false()


func test_service_payment_pickups_and_key_gate_form_playable_circuit() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var machine := level.get_node("Generated/RuleObjects/machine_production_feeder") as RuleStateObject
	var gate := level.get_node("Generated/Gates/gate_production_key") as AccessGate
	assert_bool(machine.interact()).is_false()
	economy.close_service()
	assert_bool(gate.try_open()).is_false()
	var parts := level.get_node("Generated/Resources/pickup_service_parts") as DebugPickup
	parts._on_body_entered(level._player)
	assert_int(level._player.inventory.count("service_parts")).is_equal(10)
	assert_bool(machine.interact()).is_false()
	assert_int(level._player.inventory.count("service_parts")).is_equal(10)
	economy.close_service()
	assert_int(level._player.inventory.count("service_parts")).is_equal(10)
	assert_bool(machine.interact()).is_false()
	assert_bool(economy.confirm_service()).is_true()
	assert_bool(economy.confirm_service()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_int(level._player.inventory.count("service_parts")).is_equal(0)
	assert_bool(machine.interact()).is_false()
	var reward := level.get_node("Generated/Resources/pickup_lift_ammo") as DebugPickup
	reward._on_body_entered(level._player)
	assert_int(level._player.inventory.count("heavy_ammo")).is_equal(28)
	var key := level.get_node("Generated/Resources/pickup_production_key") as DebugPickup
	key._on_body_entered(level._player)
	assert_bool(gate.try_open()).is_true()
	assert_int(level._player.inventory.count("production_key")).is_equal(1)


func test_checkpoint_restores_inventory_purchases_keys_and_world_together() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var player := level._player
	var pickup := level.get_node("Generated/Resources/pickup_lift_ammo") as DebugPickup
	pickup._on_body_entered(player)
	player.inventory.sell("trade_parts", 10)
	assert_bool(economy.buy("light_pack")).is_true()
	var expected := player.inventory.capture()
	level.activate_checkpoint(&"inventory_test", Vector2(1900, 620))
	player.inventory.spend("light_ammo", 10)
	player.inventory.sell("trade_parts", 10)
	level.retry_from_checkpoint()
	assert_bool(player.inventory.capture() == expected).is_true()
	assert_bool(pickup.is_collected()).is_true()
	pickup._on_body_entered(player)
	assert_bool(player.inventory.capture() == expected).is_true()


func test_reload_checkpoint_and_json_roundtrip_preserve_partial_reload() -> void:
	var level := _level()
	var launcher := level._player.probe_launcher
	launcher.set_physics_process(false)
	for shot: int in 4:
		launcher._fire_probe(0)
	launcher.advance_weapon_timers(0.25)
	level.activate_checkpoint(&"reload_test", level._player.position)
	launcher.advance_weapon_timers(1.0)
	level.retry_from_checkpoint()
	assert_float(launcher.reload_remaining(0)).is_equal_approx(0.4, 0.0001)
	var serialized := JSON.parse_string(JSON.stringify(launcher.capture_weapon_state())) as Dictionary
	launcher.restore_weapon_state(serialized)
	assert_int(launcher.magazine_remaining(0, 4)).is_equal(0)
	assert_float(launcher.reload_remaining(0)).is_equal_approx(0.4, 0.0001)
	launcher._fire_probe(0)
	assert_int(level._player.inventory.count("light_ammo")).is_equal(116)
	launcher.restore_weapon_state({})
	assert_int(launcher.magazine_remaining(0, 4)).is_equal(4)
	assert_float(launcher.reload_remaining(0)).is_equal(0.0)


func test_primary_four_shots_reload_cannot_be_bypassed_by_secondary() -> void:
	var level := _level()
	var launcher := level._player.probe_launcher
	launcher.set_physics_process(false)
	for shot: int in 4:
		launcher._fire_probe(0)
	assert_int(level._player.inventory.count("light_ammo")).is_equal(116)
	assert_int(launcher.magazine_remaining(0, 4)).is_equal(0)
	assert_float(launcher.reload_remaining(0)).is_equal(0.65)
	assert_str(level._hud.primary_magazine_text()).contains("[ ][ ][ ][ ]")
	assert_str(level._hud.primary_magazine_text()).contains("RECARGA")
	assert_object(level._player.sfx.profile.stream_for(&"reload")).is_not_null()
	launcher._fire_probe(1)
	launcher._fire_probe(0)
	assert_int(level._player.inventory.count("heavy_ammo")).is_equal(15)
	assert_int(level._player.inventory.count("light_ammo")).is_equal(116)
	launcher.advance_weapon_timers(0.64)
	launcher._fire_probe(0)
	assert_int(level._player.inventory.count("light_ammo")).is_equal(116)
	launcher.advance_weapon_timers(0.02)
	launcher._fire_probe(0)
	assert_int(level._player.inventory.count("light_ammo")).is_equal(115)
	assert_int(launcher.magazine_remaining(0, 4)).is_equal(3)
	assert_str(level._hud.primary_magazine_text()).contains("[■][■][■][ ]")


func test_two_weapons_consume_distinct_ammo_and_apply_configured_damage() -> void:
	var level := _level()
	var launcher := level._player.probe_launcher
	assert_float(float(level.economy_profile.weapons[0].damage)).is_equal(5.0)
	assert_float(float(level.economy_profile.weapons[0].cooldown)).is_equal(0.20)
	assert_float(float(level.economy_profile.weapons[1].damage)).is_equal(14.0)
	assert_float(float(level.economy_profile.weapons[1].cooldown)).is_equal(0.48)
	for index: int in 2:
		launcher._fire_probe(index)
		var found := false
		for node: Node in level.get_node("Generated").get_children():
			if node is AimProbe:
				assert_float((node as AimProbe).effect_amount).is_equal(float(level.economy_profile.weapons[index].damage))
				assert_vector((node as AimProbe).missile_sprite.scale).is_equal(Vector2.ONE * float(level.economy_profile.weapons[index].projectile_scale))
				assert_vector((node as AimProbe).scale).is_equal(Vector2.ONE)
				assert_float(((node.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D).radius).is_equal(6.0)
				node.free()
				found = true
		assert_bool(found).is_true()
	assert_int(level._player.inventory.count("light_ammo")).is_equal(119)
	var art := level._player.visual._ball_visual
	assert_float(art._equipment_base_scale).is_equal(2.0)
	art.set_state(&"idle")
	assert_vector(art._action_equipment.scale).is_equal(Vector2(2, 2))
	art.set_state(&"action")
	assert_float(art._action_equipment.scale.x).is_greater(1.9)
	assert_int(level._player.inventory.count("heavy_ammo")).is_equal(15)
	level._player.inventory.spend("heavy_ammo", 15)
	launcher._fire_probe(1)
	assert_int(level._player.inventory.count("heavy_ammo")).is_equal(0)
	for node: Node in level.get_node("Generated").get_children():
		assert_bool(node is AimProbe).is_false()


func test_profile_and_key_references_are_validated() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	var profile := (load("res://data/content/workshop_economy.tres") as RunEconomyDefinition).duplicate(true) as RunEconomyDefinition
	assert_array(Array(profile.validation_errors(spec))).is_empty()
	profile.pickup_rewards["missing_pickup"] = {"items": {"no_such_item": 1}}
	assert_array(Array(profile.validation_errors(spec))).is_not_empty()


func test_service_stock_and_key_reward_cannot_be_accidentally_removed() -> void:
	var spec := LevelSpecLoader.load_file("res://data/levels/w0_01_coalition_workshop.json").spec
	var profile := (load("res://data/content/workshop_economy.tres") as RunEconomyDefinition).duplicate(true) as RunEconomyDefinition
	profile.pickup_rewards.erase("pickup_service_parts")
	profile.pickup_rewards.erase("pickup_production_key")
	assert_int(profile.validation_errors(spec).size()).is_greater_equal(2)


func test_secondary_input_mapping_and_menu_release_guard() -> void:
	var has_mouse := false
	var has_pad := false
	for event: InputEvent in InputMap.action_get_events(InputActions.ATTACK_SECONDARY):
		has_mouse = has_mouse or event is InputEventMouseButton
		has_pad = has_pad or event is InputEventJoypadMotion
	assert_bool(has_mouse and has_pad).is_true()
	var level := _level()
	Input.action_press(InputActions.ATTACK_SECONDARY)
	level._player.suppress_gameplay_input_until_released()
	level._player._update_input_release_guard()
	assert_bool(level._player.probe_launcher.input_enabled).is_false()
	Input.action_release(InputActions.ATTACK_SECONDARY)
	level._player._update_input_release_guard()
	assert_bool(level._player.probe_launcher.input_enabled).is_true()


func test_old_checkpoint_beyond_new_gate_preserves_access() -> void:
	var level := _level()
	level.activate_checkpoint(&"legacy", Vector2(6300, 600))
	level._checkpoint.world_rule_state.erase("inventory")
	level.retry_from_checkpoint()
	assert_int(level._player.inventory.count("production_key")).is_equal(1)


func test_lift_reward_requires_ascent_and_key_is_within_jump_envelope() -> void:
	var level := _level()
	var lift := level.get_node("Generated/Platforms/platform_restored_lift") as DebugPlatform
	var key := level.get_node("Generated/Resources/pickup_production_key") as DebugPickup
	var profile := level._player.movement_profile
	var jump_height := profile.jump_velocity * profile.jump_velocity / (2.0 * profile.gravity)
	var top_surface := lift.position.y + lift.motion_distance_y() - lift.size.y * 0.5 + lift.collision_surface_depth
	assert_float(absf(key.position.x - lift.position.x)).is_less(lift.size.x * 0.5)
	assert_float(top_surface - 24.0 - key.position.y).is_less(jump_height)
	assert_float(650.0 + 32.0 - 24.0 - key.position.y).is_greater(jump_height + 100.0)


func test_encounter_reward_does_not_repeat_after_checkpoint_restore() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	economy._reward_encounter(&"encounter_arrival_scout", &"neutralized")
	level.activate_checkpoint(&"paid", Vector2(1800, 600))
	level.retry_from_checkpoint()
	economy._reward_encounter(&"encounter_arrival_scout", &"neutralized")
	assert_int(level._player.inventory.satoshis).is_equal(40)
	assert_int(level._player.inventory.count("trade_parts")).is_equal(0)


func test_three_police_views_pay_loot_before_shop_and_other_balls() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var count := 0
	for pair: Array in [["encounter_arrival_scout", "gate_reception"], ["encounter_arrival_pair", "gate_arrival_pair"], ["encounter_arrival_squad", "gate_arrival_squad"]]:
		count += 1
		var observer := level.get_node("Generated/EncounterObservers/" + pair[0]) as EncounterRuntimeObserver
		var gate := level.get_node("Generated/Gates/" + pair[1]) as AccessGate
		assert_int(observer._actors.size()).is_equal(count)
		assert_bool(gate.is_open()).is_false()
		assert_float(gate.position.x).is_less(economy.shop.position.x)
		for actor: CombatTarget in observer._actors:
			actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
			actor.conflict_state.neutralize()
			var drop := economy.loot.drops["loot_" + String(actor.stable_id)] as DebugPickup
			assert_bool(drop.is_available()).is_true()
			drop.advance_drop(drop.presentation.drop_arc_seconds)
			drop._on_body_entered(level._player)
		await get_tree().process_frame
		await get_tree().process_frame
		assert_bool(gate.is_open()).is_true()
		assert_bool(gate.is_collision_enabled()).is_false()
	assert_int(level._player.inventory.count("social_contract")).is_equal(70)
	assert_bool(level._player.inventory.sell("social_contract", 70)).is_true()
	assert_int(level._player.inventory.satoshis).is_equal(180)
	assert_bool(economy.buy("light_pack")).is_true()
	assert_bool(economy.buy("heavy_pack")).is_true()
	for actor: Node2D in level.get_node("Generated/Actors").get_children():
		assert_float(actor.position.x).is_greater(economy.shop.position.x)


func test_later_mutualist_services_require_payment_without_repeated_dialogue() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	assert_object(level.get_node_or_null("Generated/Actors/mutualist_current_operator/NpcDialogue")).is_not_null()
	for id: String in ["mutualist_final_dispatch_operator", "crew_mutualist"]:
		assert_object(level.get_node_or_null("Generated/Actors/" + id + "/NpcDialogue")).is_null()
	for pair: Array in [["machine_dispatch_feeder", "pickup_dispatch_ammo"], ["crew_power", "pickup_crew_ammo"]]:
		var machine := level.get_node("Generated/RuleObjects/" + pair[0]) as RuleStateObject
		assert_bool(machine.interact()).is_false()
		assert_bool(economy.confirm_service()).is_false()
		(level.get_node("Generated/Resources/" + pair[1]) as DebugPickup)._on_body_entered(level._player)
		assert_int(level._player.inventory.count("service_parts")).is_equal(10)
		assert_bool(machine.interact()).is_false()
		assert_bool(economy.confirm_service()).is_true()
		assert_int(level._player.inventory.count("service_parts")).is_equal(0)
		assert_int(machine.current_state).is_equal(RuleStateObject.State.OCCUPIED)
		assert_bool(economy.confirm_service()).is_false()
	await get_tree().process_frame


func test_shop_inventory_filters_and_confirms_exact_quantities() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var inventory := level._player.inventory
	inventory.grant_once("sale_test", {"trade_parts": 13, "production_key": 1})
	assert_array(economy.sellable_items()).contains(["trade_parts"])
	assert_bool("production_key" in economy.sellable_items()).is_false()
	assert_bool("egoist_milk" in economy.sellable_items()).is_false()
	economy.open_shop()
	economy.show_shop_page("sell")
	economy.select_sale("trade_parts")
	economy.change_sale_quantity(3)
	assert_int(economy._sale_quantity).is_equal(4)
	assert_int(inventory.count("trade_parts")).is_equal(13)
	economy.shop_back()
	assert_int(inventory.count("trade_parts")).is_equal(13)
	economy.select_sale("trade_parts")
	economy.change_sale_quantity(3)
	assert_bool(economy.confirm_sale()).is_true()
	assert_int(inventory.count("trade_parts")).is_equal(9)
	assert_int(inventory.satoshis).is_equal(8)
	assert_bool(economy.confirm_sale()).is_false()
	economy.select_sale("trade_parts")
	economy.change_sale_quantity(999)
	assert_int(economy._sale_quantity).is_equal(9)
	assert_bool(economy.confirm_sale()).is_true()
	assert_bool("trade_parts" in economy.sellable_items()).is_false()
	economy.close_shop()
	assert_bool(get_tree().paused).is_false()
	await get_tree().process_frame


func test_shop_closes_unpauses_and_guards_held_fire() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	economy.open_shop()
	assert_bool(get_tree().paused).is_true()
	economy.close_shop()
	assert_bool(get_tree().paused).is_false()
	assert_bool(level._player.is_gameplay_input_suppressed()).is_true()
	await get_tree().process_frame


func test_nearby_dialogues_show_only_the_nearest_speaker() -> void:
	var level := _level()
	var player := level._player
	player.global_position = Vector2.ZERO
	var first := auto_free(NpcDialogueBubble.new()) as NpcDialogueBubble
	var second := auto_free(NpcDialogueBubble.new()) as NpcDialogueBubble
	first.configure("A", ["Texto A"], false)
	second.configure("B", ["Texto B"], false)
	add_child(first)
	add_child(second)
	first.position = Vector2(10, 0)
	second.position = Vector2(100, 0)
	first._on_body_entered(player)
	second._on_body_entered(player)
	first._process(0.0)
	second._process(0.0)
	assert_bool(first._panel.visible).is_true()
	assert_bool(second._panel.visible).is_false()


func test_repeated_npc_archetypes_keep_separate_checkpoint_positions() -> void:
	var level := _level()
	var actors := level.get_node("Generated/Actors")
	var positions: Dictionary = {}
	for actor: CombatTarget in actors.get_children():
		assert_bool(positions.has(actor.stable_id)).is_false()
		positions[actor.stable_id] = actor.position
	level.activate_checkpoint(&"actor_positions", Vector2(120, 606))
	for actor: CombatTarget in actors.get_children():
		actor.position.x += 55
	level.retry_from_checkpoint()
	for actor: CombatTarget in actors.get_children():
		assert_bool(actor.position == positions[actor.stable_id]).is_true()
