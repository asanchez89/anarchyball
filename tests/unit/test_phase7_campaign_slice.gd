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
