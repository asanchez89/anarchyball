extends GdUnitTestSuite


func _inventory() -> RunInventory:
	var inventory := RunInventory.new()
	inventory.configure(load("res://data/content/workshop_economy.tres") as RunEconomyDefinition)
	return inventory


func _level() -> LevelBuilder:
	var scene := load("res://levels/world_0/w0_01_coalition_workshop.tscn") as PackedScene
	var level := auto_free(scene.instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	assert_bool(level.last_validation.is_valid()).is_true()
	return level


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


func test_two_weapons_consume_distinct_ammo_and_apply_configured_damage() -> void:
	var level := _level()
	var launcher := level._player.probe_launcher
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
