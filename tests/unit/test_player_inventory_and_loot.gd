extends GdUnitTestSuite


func _level() -> LevelBuilder:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	return level


func after_test() -> void:
	get_tree().paused = false


func test_loot_is_physical_and_restores_uncollected_or_collected_without_duplication() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var observer := level.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver
	var actor := observer._actors[0]
	var drop := economy.loot.drops["loot_" + String(actor.stable_id)] as DebugPickup
	var drop_id := String(drop.pickup_id)
	assert_bool(drop.is_available()).is_false()
	actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	actor.conflict_state.neutralize()
	assert_bool(drop.is_available()).is_true()
	assert_int(level._player.inventory.count("social_contract")).is_equal(0)
	assert_vector(drop.position).is_equal(actor.position)
	drop.advance_drop(drop.presentation.drop_arc_seconds)
	assert_vector(drop.position).is_equal(level._grounded_placement(actor.position.x + 56.0, actor.position.y, drop.visible_floor_offset()))
	level.activate_checkpoint(&"uncollected", Vector2(500, 600))
	drop._on_body_entered(level._player)
	assert_int(level._player.inventory.count("social_contract")).is_equal(20)
	level.retry_from_checkpoint()
	drop = economy.loot.drops[drop_id] as DebugPickup
	assert_bool(drop.is_available()).is_true()
	assert_bool(drop.is_collected()).is_false()
	assert_int(level._player.inventory.count("social_contract")).is_equal(0)
	drop._on_body_entered(level._player)
	level.activate_checkpoint(&"collected", Vector2(500, 600))
	level.retry_from_checkpoint()
	economy.loot.release(drop_id)
	assert_bool(economy.loot.drops.has(drop_id)).is_false()
	assert_bool(economy.loot.capture()[drop_id].collected).is_true()
	assert_int(level._player.inventory.count("social_contract")).is_equal(20)


func test_humorous_drops_have_distinct_art_and_visible_ground_size() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	for pair: Array in [["encounter_arrival_scout", "social_contract", 20], ["encounter_depot_patrol", "communal_toothbrush", 10], ["encounter_storage_cache", "egoist_milk", 10]]:
		var observer := level.get_node("Generated/EncounterObservers/" + pair[0]) as EncounterRuntimeObserver
		var actor := observer._actors[0]
		var drop := economy.loot.drops["loot_" + String(actor.stable_id)] as DebugPickup
		assert_bool(drop.is_available()).is_false()
		assert_int(drop.inventory_reward.items[pair[1]]).is_equal(pair[2])
		var art := drop._sprite.texture as AtlasTexture
		assert_object(art.atlas).is_same(economy.profile.item_art[pair[1]])
		var visible_size := art.get_size() * drop._sprite.scale
		assert_float(maxf(visible_size.x, visible_size.y)).is_equal_approx(84.0, 0.01)
		var grid := drop._sprite.material as ShaderMaterial
		assert_bool((visible_size / (grid.get_shader_parameter("logical_size") as Vector2)).is_equal_approx(Vector2(3, 3))).is_true()
		assert_bool(art.atlas.get_image().get_used_rect().size.x < art.atlas.get_width()).is_true()
		actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
		actor.conflict_state.neutralize()
		drop.advance_drop(drop.presentation.drop_arc_seconds)
		drop._on_body_entered(level._player)
		assert_int(level._player.inventory.count(pair[1])).is_equal(pair[2])
		assert_bool(level._player.inventory.sell(pair[1], pair[2])).is_true()


func test_truce_cedes_loot_without_attacking_neutral_survivors_and_restores_it() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	for pair: Array in [["encounter_depot_patrol", "communal_toothbrush"], ["encounter_storage_cache", "egoist_milk"]]:
		var observer := level.get_node("Generated/EncounterObservers/" + pair[0]) as EncounterRuntimeObserver
		var challenge := observer.challenge
		challenge.started = true
		challenge.finish(&"survive_ceasefire")
		assert_bool(observer.is_resolved()).is_true()
		level.activate_checkpoint(&"ceded_loot", Vector2(500, 600))
		level.retry_from_checkpoint()
		for actor: CombatTarget in observer._actors:
			var drop := economy.loot.drops["loot_" + String(actor.stable_id)] as DebugPickup
			assert_bool(drop.is_available()).is_true()
			drop.advance_drop(drop.presentation.drop_arc_seconds)
			drop._on_body_entered(level._player)
			economy.loot.release(String(drop.pickup_id))
			drop._on_body_entered(level._player)
		assert_int(level._player.inventory.count(pair[1])).is_equal(observer._actors.size() * 10)


func test_retry_before_defeat_hides_loot_and_legacy_payment_does_not_duplicate() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	var actor := (level.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver)._actors[0]
	var drop := economy.loot.drops["loot_" + String(actor.stable_id)] as DebugPickup
	actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	actor.conflict_state.neutralize()
	level.retry_from_checkpoint()
	assert_bool(drop.is_available()).is_false()
	level._player.inventory.grant_once("encounter:encounter_arrival_scout", {"trade_parts": 20}, 40)
	economy.loot.restore({})
	assert_bool(economy.loot.drops.has(String(drop.pickup_id))).is_false()
	drop._on_body_entered(level._player)
	assert_int(level._player.inventory.count("trade_parts")).is_equal(20)


func test_player_menu_pauses_shows_actual_inventory_and_closes_with_both_devices() -> void:
	var level := _level()
	var menu := (level.get_node("Generated/Economy") as WorkshopEconomy).player_menu
	level._player.inventory.grant_once("test", {"trade_parts": 20, "production_key": 1}, 40)
	for event: InputEvent in InputMap.action_get_events(InputActions.PLAYER_MENU):
		var pressed := event.duplicate() as InputEvent
		pressed.set("pressed", true)
		menu._unhandled_input(pressed)
		assert_bool(get_tree().paused).is_true()
		assert_object(menu.overlay).is_not_null()
		assert_str(menu.stats.text).contains("40 sats")
		assert_str(menu.inventory_label.text).contains("Piezas recuperadas  ×20")
		assert_str(menu.inventory_label.text).contains("Llave de producción  ×1")
		(menu.overlay as PlayerInventoryMenu.MenuOverlay)._input(pressed)
		assert_bool(get_tree().paused).is_false()
		assert_object(menu.overlay).is_null()
		await get_tree().process_frame
	get_tree().paused = true
	menu.open_menu()
	assert_object(menu.overlay).is_null()


func test_expanded_shop_and_inventory_scroll_stay_inside_panels() -> void:
	var level := _level()
	var economy := level.get_node("Generated/Economy") as WorkshopEconomy
	economy.profile = economy.profile.duplicate(true)
	for index: int in 12:
		var item := "test_salvage_%d" % index
		economy.profile.items[item] = {"label": "Mercancía %d" % index, "sell_sats": 1}
		economy.player.inventory.stacks[item] = 1
	economy.open_shop()
	economy.show_shop_page("sell")
	await get_tree().process_frame
	await get_tree().process_frame
	var panel := economy._menu.get_node("ShopPanel") as PanelContainer
	var scroll := panel.find_child("ShopScroll", true, false) as ScrollContainer
	assert_float(panel.size.y).is_less_equal(660.0)
	assert_bool(scroll.follow_focus).is_true()
	var buttons := panel.find_children("*", "Button", true, false)
	(buttons.back() as Button).grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(scroll.scroll_vertical).is_greater(0)
	assert_bool(scroll.get_global_rect().encloses((buttons.back() as Button).get_global_rect())).is_true()
	economy.close_shop()
	await get_tree().process_frame
	economy.player_menu.open_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	var overlay := economy.player_menu.overlay as PlayerInventoryMenu.MenuOverlay
	for event: InputEvent in InputMap.action_get_events("ui_down"):
		var pressed := event.duplicate() as InputEvent
		pressed.set("pressed", true)
		var previous := overlay.inventory_scroll.scroll_vertical
		overlay._input(pressed)
		assert_int(overlay.inventory_scroll.scroll_vertical).is_greater(previous)
	economy.player_menu.close_menu()
