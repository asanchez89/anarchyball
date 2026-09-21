extends GdUnitTestSuite

const LEVEL_PATH := "res://data/levels/w0_01_first_aggression.json"
const PROFILE_PATH := "res://data/level_profiles/w0_01_first_aggression.json"
const CATALOG_PATH := "res://data/content/default_catalog.tres"


func test_campaign_world_and_first_mission_are_registered() -> void:
	var world := load("res://data/campaign/world_00_anarchist_frontier.tres") as WorldDefinition
	assert_object(world).is_not_null()
	assert_int(world.validation_errors().size()).is_equal(0)
	assert_str(world.world_id).is_equal("world_00_anarchist_frontier")
	assert_str(world.missions[0].mission_id).is_equal("w0_01_first_aggression")
	assert_object(world.missions[0].mission_scene).is_not_null()


func test_campaign_progress_round_trips_and_unlocks_in_definition_order() -> void:
	var world := WorldDefinition.new()
	world.world_id = &"world_fixture"
	for mission_id: StringName in [&"mission_one", &"mission_two"]:
		var mission := CampaignMissionDefinition.new()
		mission.mission_id = mission_id
		mission.display_name = String(mission_id)
		world.missions.append(mission)
	var state := CampaignProgressState.new()
	state.world_id = world.world_id
	state.active_mission_id = &"mission_one"
	state.complete(&"mission_one", world)
	var restored := CampaignProgressState.from_dictionary(state.to_dictionary())

	assert_str(restored.active_mission_id).is_equal("mission_two")
	assert_bool(&"mission_one" in restored.completed_mission_ids).is_true()


func test_checkpoint_paths_are_isolated_per_level() -> void:
	assert_str(LocalSaveStore.path_for_level(&"w0_01_first_aggression")).is_equal("user://saves/checkpoints/w0_01_first_aggression.json")
	assert_bool(LocalSaveStore.path_for_level(&"w0_01_first_aggression") != LocalSaveStore.path_for_level(&"occupancy_workshop_draft")).is_true()
	assert_str(LocalSaveStore.path_for_level(&"Invalid ID")).is_empty()


func test_first_aggression_level_profile_and_required_encounter_validate() -> void:
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var registry := ContentRegistry.new()
	assert_bool(registry.register_catalog(catalog, CATALOG_PATH)).is_true()
	var load_result := LevelSpecLoader.load_file(LEVEL_PATH)
	var validation := LevelValidator.validate(load_result.spec, registry)
	var profile_result := LevelPlaytestProfile.load_and_validate(PROFILE_PATH, PackedStringArray(["w0_01_first_aggression"]))

	assert_bool(validation.is_valid()).is_true()
	assert_int((profile_result["errors"] as PackedStringArray).size()).is_equal(0)
	assert_bool(bool(((load_result.spec.data["encounters"] as Array)[0] as Dictionary)["required_for_completion"])).is_true()
	assert_int((load_result.spec.data["checkpoints"] as Array).size()).is_equal(1)
	assert_int((load_result.spec.data["encounters"] as Array).size()).is_equal(2)
	var optional_platforms := (load_result.spec.data["platforms"] as Array).filter(
		func(platform: Dictionary) -> bool: return not bool(platform.get("required", true))
	)
	assert_int(optional_platforms.size()).is_equal(7)
	var route_tags: Array = []
	for platform_value: Variant in optional_platforms:
		route_tags.append_array((platform_value as Dictionary).get("route_tags", []) as Array)
	assert_array(route_tags).contains(["upper_supply_route", "merchant_rescue_vantage", "upper_ruin_bypass"])


func test_optional_roadblock_adds_two_telegraphed_adversaries_without_blocking_exit() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	var validation := builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog)
	assert_bool(validation.is_valid()).is_true()
	var roadblock_adversaries: Array[CombatTarget] = [
		builder.get_node("Generated/Encounters/enemy_frontier_raider") as CombatTarget,
		builder.get_node("Generated/Encounters/enemy_frontier_lookout") as CombatTarget,
	]
	for adversary: CombatTarget in roadblock_adversaries:
		assert_object(adversary).is_not_null()
		assert_int(adversary.initial_state).is_equal(ConflictStateComponent.State.NEUTRAL)
		assert_int(adversary.behavior).is_equal(CombatTarget.Behavior.ATTACK_PLAYER)
	assert_array(builder.required_unresolved_encounter_ids()).contains_exactly([&"encounter_merchant_robbery"])


func test_neutral_frontier_guide_delivers_short_mechanical_dialogue() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	var validation := builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog)
	var guide := builder.get_node_or_null("Generated/Actors/frontier_tutorial_guide") as CombatTarget
	var dialogue := guide.get_node_or_null("NpcDialogue") as NpcDialogueBubble

	assert_bool(validation.is_valid()).is_true()
	assert_object(guide).is_not_null()
	assert_int(guide.initial_state).is_equal(ConflictStateComponent.State.NEUTRAL)
	assert_object(dialogue).is_not_null()
	assert_int(dialogue.lines.size()).is_equal(3)
	assert_str(dialogue.lines[0]).contains("neutral")
	assert_str(dialogue.lines[1]).contains("agresor")
	assert_str(dialogue.lines[2]).contains("RESOLVE")
	assert_bool(dialogue.start()).is_true()
	assert_str(dialogue.current_line()).is_equal(dialogue.lines[0])
	assert_bool(dialogue.is_typing()).is_true()
	assert_bool(dialogue.advance()).is_true()
	assert_bool(dialogue.is_typing()).is_false()
	assert_bool(dialogue.advance()).is_true()
	assert_str(dialogue.current_line()).is_equal(dialogue.lines[1])
	var bubble_art := dialogue.get_node("DialogueBubble/PixelBubbleArt") as TextureRect
	var bubble_margin := dialogue.get_node("DialogueBubble/MarginContainer") as MarginContainer
	var line_label := dialogue.get_node("DialogueBubble/MarginContainer/VBoxContainer/Line") as Label
	assert_str(bubble_art.texture.resource_path).is_equal("res://assets/art/ui/dialogue_bubble_16bit.png")
	assert_float(bubble_margin.anchor_right).is_equal(1.0)
	assert_float(bubble_margin.anchor_bottom).is_equal(1.0)
	assert_bool(bubble_margin.clip_contents).is_true()
	assert_int(bubble_margin.get_theme_constant("margin_left")).is_equal(34)
	assert_int(bubble_margin.get_theme_constant("margin_top")).is_equal(30)
	assert_int(bubble_margin.get_theme_constant("margin_bottom")).is_equal(72)
	assert_str(line_label.get_theme_font("font").resource_path).is_equal("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf")
	assert_int(line_label.get_theme_font_size("font_size")).is_equal(10)
	var player := builder.get_node("Generated/Player") as PlayerController
	var visual := guide.get_node("BallVisual") as BallVisual
	player.global_position.x = guide.global_position.x - 80.0
	guide._on_dialogue_player_proximity_changed(player, true)
	guide._face_dialogue_player()
	var left_scale := visual.scale.x
	player.global_position.x = guide.global_position.x + 80.0
	guide._face_dialogue_player()
	assert_float(visual.scale.x).is_equal(-left_scale)


func test_required_for_completion_rejects_non_boolean_values() -> void:
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var registry := ContentRegistry.new()
	registry.register_catalog(catalog, CATALOG_PATH)
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data.duplicate(true)
	((data["encounters"] as Array)[0] as Dictionary)["required_for_completion"] = "yes"
	var validation := LevelValidator.validate(LevelSpec.new(data, "res://invalid_required_encounter.json"), registry)
	var found := false
	for issue: ValidationIssue in validation.issues:
		found = found or (issue.code == &"invalid_type" and issue.field_path == "encounters[0].required_for_completion")
	assert_bool(found).is_true()


func test_builder_blocks_exit_until_required_encounter_resolves() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	var validation := builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog)
	assert_bool(validation.is_valid()).is_true()
	assert_array(builder.required_unresolved_encounter_ids()).contains_exactly([&"encounter_merchant_robbery"])
	var observer := builder.get_node("Generated/EncounterObservers/encounter_merchant_robbery") as EncounterRuntimeObserver
	assert_bool(observer.try_resolve(&"force_robber_surrender")).is_true()
	assert_array(builder.required_unresolved_encounter_ids()).is_empty()


func test_robber_declares_aggression_before_third_party_impact() -> void:
	var robber := auto_free((load("res://src/debug/combat_target.tscn") as PackedScene).instantiate()) as CombatTarget
	var merchant := auto_free((load("res://src/debug/combat_target.tscn") as PackedScene).instantiate()) as CombatTarget
	var player := auto_free((load("res://src/actors/player/player.tscn") as PackedScene).instantiate()) as PlayerController
	robber.name = "Robber"
	merchant.name = "Merchant"
	player.name = "Player"
	robber.behavior = CombatTarget.Behavior.ATTACK_THIRD_PARTY
	robber.aggressor_reason = ConflictStateComponent.AggressorReason.FORCED_CONFISCATION
	robber.telegraph_delay = 0.1
	robber.commitment_impact_delay = 0.5
	robber.activation_distance = 1000.0
	robber.protected_target_id = &"merchant"
	robber.protected_target_path = NodePath("../Merchant")
	robber.player_path = NodePath("../Player")
	add_child(robber)
	add_child(merchant)
	add_child(player)
	var initial_resolve := merchant.resolve.current_resolve

	robber._update_behavior(1.0)
	robber._update_behavior(1.0)
	assert_int(robber.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
	assert_float(merchant.resolve.current_resolve).is_equal(initial_resolve)
	robber._update_pending_third_party_impact(0.25)
	assert_float(merchant.resolve.current_resolve).is_equal(initial_resolve)


func test_report_counts_restarted_attempt_in_completion_rate() -> void:
	var profile := (LevelPlaytestProfile.load_and_validate(PROFILE_PATH)["data"] as Dictionary)
	var completed := {"level_id": "w0_01_first_aggression", "run_outcome": "completed", "events": [], "playtest_profile": "first_clear"}
	var restarted := {"level_id": "w0_01_first_aggression", "run_outcome": "restarted", "events": [], "playtest_profile": "first_clear"}
	var report := TelemetryPlaytestReport.summarize([completed, restarted], profile)

	assert_int(int(report["total_runs"])).is_equal(2)
	assert_int(int(report["completed_runs"])).is_equal(1)
	assert_float(float(report["completion_rate"])).is_equal(0.5)
