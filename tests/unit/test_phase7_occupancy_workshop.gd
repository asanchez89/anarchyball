extends GdUnitTestSuite

const LEVEL_PATH := "res://data/levels/w0_03_occupancy_workshop.json"
const PROFILE_PATH := "res://data/level_profiles/w0_03_occupancy_workshop.json"
const CATALOG_PATH := "res://data/content/default_catalog.tres"


func test_mutualist_content_and_third_campaign_mission_are_registered() -> void:
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var registry := ContentRegistry.new()
	assert_bool(registry.register_catalog(catalog, CATALOG_PATH)).is_true()
	var mutualist := registry.get_definition(ContentRegistry.Kind.ENEMY_ARCHETYPE, &"npc_mutualist_operator") as EnemyArchetype
	var claimant := registry.get_definition(ContentRegistry.Kind.ENEMY_ARCHETYPE, &"npc_mutualist_claimant") as EnemyArchetype
	var encounter := registry.get_definition(ContentRegistry.Kind.ENCOUNTER_DEFINITION, &"encounter_occupancy_title_claim") as EncounterDefinition
	var world := load("res://data/campaign/world_00_anarchist_frontier.tres") as WorldDefinition

	assert_object(mutualist).is_not_null()
	assert_int(mutualist.initial_conflict_state).is_equal(ConflictStateComponent.State.NEUTRAL)
	assert_int(mutualist.dialogue_lines.size()).is_equal(3)
	assert_bool(mutualist.dialogue_auto_start).is_false()
	assert_object(claimant).is_not_null()
	assert_int(claimant.initial_conflict_state).is_equal(ConflictStateComponent.State.DISPUTED)
	assert_array(claimant.dialogue_lines).is_empty()
	assert_object(encounter).is_not_null()
	assert_array(encounter.allowed_resolutions).contains_exactly([&"neutralize_enforcer", &"operate_alternate_machine"])
	assert_int(world.missions.size()).is_equal(3)
	assert_str(world.missions[2].mission_id).is_equal("w0_03_occupancy_workshop")


func test_completed_contract_bridge_progress_reconciles_to_workshop() -> void:
	var world := load("res://data/campaign/world_00_anarchist_frontier.tres") as WorldDefinition
	var progress := CampaignProgressState.new()
	progress.world_id = world.world_id
	progress.active_mission_id = &"w0_02_contract_bridge"
	progress.completed_mission_ids = [&"w0_01_first_aggression", &"w0_02_contract_bridge"]
	progress.reconcile(world)

	assert_str(progress.active_mission_id).is_equal("w0_03_occupancy_workshop")


func test_workshop_starts_with_a_gameplay_briefing_for_visible_actor_types() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = true
	add_child(builder)
	var validation := builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog)
	var flow := builder.get_node_or_null("Generated/Flow") as SliceFlowController

	assert_bool(validation.is_valid()).is_true()
	assert_object(flow).is_not_null()
	assert_int(flow.briefing_card_count()).is_equal(5)
	assert_int(flow.current_briefing_index()).is_equal(0)
	var image := flow.get_node("MenuOverlay/BriefingPanel/BriefingImage") as TextureRect
	var panel := flow.get_node("MenuOverlay/BriefingPanel") as VBoxContainer
	var heading := panel.get_child(0) as Label
	assert_object(image).is_not_null()
	assert_str(heading.get_theme_font("font").resource_path).is_equal("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf")
	flow._on_primary_pressed()
	assert_object(image.texture).is_instanceof(AtlasTexture)
	assert_float((image.texture as AtlasTexture).region.size.x).is_equal_approx(96.0, 0.01)
	get_tree().paused = false


func test_canonical_occupancy_states_control_utility_and_exclusion() -> void:
	var root := auto_free(Node2D.new()) as Node2D
	add_child(root)
	var target := DebugPlatform.new()
	root.add_child(target)
	var machine := RuleStateObject.new()
	machine.current_state = RuleStateObject.State.ABANDONED
	machine.configure_targets([target])
	root.add_child(machine)

	assert_bool(target.is_rule_enabled()).is_false()
	assert_bool(machine.interact()).is_true()
	assert_int(machine.current_state).is_equal(RuleStateObject.State.OCCUPIED)
	assert_bool(target.is_rule_enabled()).is_true()
	assert_bool(machine.interact()).is_false()

	machine.transition_to(RuleStateObject.State.DISPUTED)
	assert_bool(target.is_rule_enabled()).is_true()
	assert_bool(machine.interact()).is_false()
	var snapshot := machine.capture_runtime_state()
	machine.transition_to(RuleStateObject.State.ABANDONED)
	assert_bool(machine.restore_runtime_state(snapshot)).is_true()
	assert_int(machine.current_state).is_equal(RuleStateObject.State.DISPUTED)


func test_machine_guidance_distinguishes_action_lesson_and_resolution() -> void:
	var machine := auto_free(RuleStateObject.new()) as RuleStateObject
	machine.current_state = RuleStateObject.State.ABANDONED
	assert_str(machine.guidance_text()).contains("APPROACH")
	machine.current_state = RuleStateObject.State.OCCUPIED
	assert_str(machine.guidance_text()).contains("NO ACTION HERE")
	assert_str(machine.guidance_text()).contains("CONTINUE RIGHT")
	machine.current_state = RuleStateObject.State.DISPUTED
	assert_str(machine.guidance_text()).contains("DO NOT ATTACK")
	assert_str(machine.guidance_text()).contains("ALTERNATE MACHINE")


func test_workshop_is_independent_standard_mission_with_extended_final_challenge() -> void:
	var load_result := LevelSpecLoader.load_file(LEVEL_PATH)
	var validation := LevelValidator.validate(load_result.spec, _registry())
	var data := load_result.spec.data
	var prototype := LevelSpecLoader.load_file("res://data/levels/occupancy_workshop_draft.json").spec
	var profile_result := LevelPlaytestProfile.load_and_validate(PROFILE_PATH, PackedStringArray(["w0_03_occupancy_workshop"]))

	assert_bool(load_result.is_success()).is_true()
	assert_bool(validation.is_valid()).is_true()
	assert_int((profile_result["errors"] as PackedStringArray).size()).is_equal(0)
	assert_str(load_result.spec.level_id()).is_equal("w0_03_occupancy_workshop")
	assert_bool(data.get("bounds") != prototype.data.get("bounds")).is_true()
	assert_int((data.get("sections") as Array).size()).is_equal(6)
	assert_int((data.get("checkpoints") as Array).size()).is_equal(2)
	assert_float(float((data.get("bounds") as Dictionary).get("width")) / 1280.0).is_between(12.0, 18.0)
	assert_object(load("res://levels/world_0/w0_03_occupancy_workshop.tscn") as PackedScene).is_not_null()


func test_workshop_distributes_resistance_and_ends_with_vertical_traversal() -> void:
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data
	var encounters := data.get("encounters", []) as Array
	var challenge_x_positions: Array[float] = []
	var challenge_sequence: Array[StringName] = []
	for encounter_value: Variant in encounters:
		var encounter := encounter_value as Dictionary
		var definition_id := StringName(String(encounter.get("definition_id")))
		if definition_id in [&"encounter_occupancy_dispute", &"encounter_ancom_patrol", &"encounter_egoist_route_dispute"]:
			challenge_x_positions.append(float(encounter.get("x")))
			challenge_sequence.append(definition_id)
	assert_int(challenge_x_positions.size()).is_greater_equal(8)
	assert_float(challenge_x_positions.min()).is_less(1080.0)
	assert_float(challenge_x_positions.max()).is_greater(20000.0)
	assert_array(challenge_sequence.slice(0, 4)).contains_exactly([
		&"encounter_occupancy_dispute", &"encounter_ancom_patrol",
		&"encounter_egoist_route_dispute", &"encounter_occupancy_dispute",
	])
	var platform_by_id: Dictionary = {}
	for platform_value: Variant in data.get("platforms", []) as Array:
		var platform := platform_value as Dictionary
		platform_by_id[String(platform.get("id"))] = platform
	var climb_ids: Array[String] = [
		"climb_lower_approach", "climb_middle", "climb_upper",
		"descent_middle", "descent_lower",
	]
	var previous_end := float((platform_by_id["ground_checkpoint_two"] as Dictionary).get("x")) + float((platform_by_id["ground_checkpoint_two"] as Dictionary).get("width"))
	for platform_id: String in climb_ids:
		var platform := platform_by_id[platform_id] as Dictionary
		var gap := float(platform.get("x")) - previous_end
		assert_float(gap).is_greater_equal(140.0)
		previous_end = float(platform.get("x")) + float(platform.get("width"))
	assert_float(float((platform_by_id["climb_lower_approach"] as Dictionary).get("y"))).is_greater(float((platform_by_id["climb_upper"] as Dictionary).get("y")))


func test_repeated_encounters_increase_visible_ball_count() -> void:
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data
	var counts: Array[int] = []
	for encounter_value: Variant in data.get("encounters", []) as Array:
		var encounter := encounter_value as Dictionary
		if String(encounter.get("definition_id")) == "encounter_occupancy_dispute":
			counts.append(int(encounter.get("enemy_count", 1)))
	assert_array(counts).contains_exactly([1, 2, 2, 2, 3])
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var final_police := builder.get_node("Generated/EncounterObservers/encounter_dispatch_roadblock") as EncounterRuntimeObserver
	var final_police_actors := final_police.get("_actors") as Array
	assert_int(final_police_actors.size()).is_equal(3)


func test_workshop_builds_world_actor_and_two_dispute_resolutions() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	var validation := builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog)
	var mutualist := builder.get_node_or_null("Generated/Actors/mutualist_current_operator") as CombatTarget
	var enforcer := builder.get_node_or_null("Generated/Encounters/enemy_occupancy_enforcer") as CombatTarget
	var claimant := builder.get_node_or_null("Generated/Encounters/npc_mutualist_claimant") as CombatTarget
	var alternate := builder.get_node_or_null("Generated/RuleObjects/machine_alternate_press") as RuleStateObject
	var observer := builder.get_node_or_null("Generated/EncounterObservers/encounter_title_claim") as EncounterRuntimeObserver

	assert_bool(validation.is_valid()).is_true()
	assert_object(mutualist).is_not_null()
	assert_int(mutualist.conflict_state.current_state).is_equal(ConflictStateComponent.State.NEUTRAL)
	assert_object(claimant).is_not_null()
	assert_object(claimant.get_node_or_null("NpcDialogue")).is_null()
	assert_int(enforcer.conflict_state.current_state).is_equal(ConflictStateComponent.State.DISPUTED)
	assert_bool(observer.is_resolved()).is_false()
	assert_bool(alternate.interact()).is_true()
	assert_bool(observer.is_resolved()).is_true()
	assert_array(builder.required_unresolved_encounter_ids()).contains_exactly([
		&"encounter_arrival_scout",
		&"encounter_restored_output_raiders",
		&"encounter_exclusion_corridor_raiders",
		&"encounter_shared_line_raiders",
		&"encounter_resolution_corridor_assault",
		&"encounter_workshop_raiders",
		&"encounter_exit_lookouts",
		&"encounter_communal_yard_assault",
		&"encounter_dispatch_roadblock",
		&"encounter_dispatch_ancom",
		&"encounter_dispatch_egoist",
		&"encounter_dispatch_mutualist",
	])


func test_neutral_mutualist_and_disputed_enforcer_are_not_offensive_targets() -> void:
	var source := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	source.stable_id = &"player"
	source.authority = CombatIdentityComponent.Authority.PLAYER
	for archetype_path: String in [
		"res://data/content/enemies/npc_mutualist_operator.tres",
		"res://data/content/enemies/enemy_occupancy_enforcer.tres",
	]:
		var archetype := load(archetype_path) as EnemyArchetype
		var identity := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
		identity.stable_id = archetype.content_id
		var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
		conflict.reset_conflict(archetype.initial_conflict_state)
		var resolve := auto_free(ResolveComponent.new()) as ResolveComponent
		resolve.maximum_resolve = archetype.maximum_resolve
		resolve.reset()
		var receiver := auto_free(EffectReceiverComponent.new()) as EffectReceiverComponent
		receiver.bind_for_test(identity, conflict, resolve)
		assert_bool(TargetValidity.evaluate(source, receiver, EffectContext.offensive()).allowed).is_false()


func test_actor_placement_rejects_unknown_archetype() -> void:
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data.duplicate(true)
	((data["actors"] as Array)[0] as Dictionary)["archetype_id"] = "missing_operator"
	var validation := LevelValidator.validate(LevelSpec.new(data, "res://invalid_actor.json"), _registry())
	var found := false
	for issue: ValidationIssue in validation.issues:
		found = found or (issue.code == &"unknown_reference" and issue.field_path == "actors[0].archetype_id")
	assert_bool(found).is_true()


func test_frontier_enemies_patrol_and_expose_pixel_status_icon() -> void:
	var archetype := load("res://data/content/enemies/enemy_ancom_patrol.tres") as EnemyArchetype
	assert_bool(archetype.is_structurally_valid()).is_true()
	assert_float(archetype.patrol_distance).is_greater(0.0)
	assert_float(archetype.patrol_speed).is_greater(0.0)
	var actor := auto_free((load("res://src/debug/combat_target.tscn") as PackedScene).instantiate()) as CombatTarget
	actor.apply_archetype(archetype)
	add_child(actor)
	var origin_x := actor.position.x
	actor._update_patrol(0.5)
	assert_float(actor.position.x).is_greater(origin_x)
	assert_float(absf(actor.position.x - origin_x)).is_less_equal(archetype.patrol_distance)
	assert_str(actor.presentation_state_id()).is_equal("move")
	var icon := actor.get_node_or_null("ConflictStatusIcon") as ConflictStatusIcon
	assert_object(icon).is_not_null()
	actor.conflict_state.begin_threatening()
	assert_int(icon.state).is_equal(ConflictStateComponent.State.THREATENING)


func test_built_enemy_actors_share_the_global_grounding_rule() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	var validation := builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog)
	assert_bool(validation.is_valid()).is_true()
	var raider := builder.get_node("Generated/Encounters/enemy_occupancy_enforcer") as CombatTarget
	var expected := WorldPropPlacement.grounded_position(
		builder.loaded_spec.data.get("platforms", []) as Array,
		raider.position.x,
		570.0,
		builder.art_surface_depth,
		WorldPropPlacement.BALL_ORIGIN_TO_FLOOR
	)
	assert_float(raider.position.y).is_equal(expected.y)


func test_early_encounters_open_their_workshop_gates_only_on_resolution() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var police_gate := builder.get_node("Generated/Gates/gate_after_police_tutorial") as AccessGate
	var police_observer := builder.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver
	assert_bool(police_gate.is_open()).is_false()
	assert_bool(police_observer.try_resolve(&"neutralize_enforcer")).is_true()
	assert_bool(police_gate.is_open()).is_true()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(police_gate.is_collision_enabled()).is_false()
	assert_object(police_gate.get_node_or_null("WarpedGateArt")).is_not_null()
	var ancom_gate := builder.get_node("Generated/Gates/gate_after_ancom_patrol") as AccessGate
	var truce_machine := builder.get_node("Generated/RuleObjects/machine_ancom_truce_one") as RuleStateObject
	assert_bool(ancom_gate.is_open()).is_false()
	assert_bool(truce_machine.interact()).is_true()
	assert_bool(ancom_gate.is_open()).is_true()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(ancom_gate.is_collision_enabled()).is_false()


func test_every_required_workshop_challenge_has_an_unskippable_gate() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var data := builder.loaded_spec.data
	var police_count := 0
	for encounter_value: Variant in data.get("encounters", []) as Array:
		var encounter := encounter_value as Dictionary
		if not bool(encounter.get("required_for_completion", false)):
			continue
		var gate_id := String(encounter.get("resolution_gate_id", ""))
		assert_str(gate_id).is_not_empty()
		var gate := builder.get_node("Generated/Gates/%s" % gate_id) as AccessGate
		assert_bool(gate.is_open()).is_false()
		var collision := gate.get_child(0) as CollisionShape2D
		assert_float((collision.shape as RectangleShape2D).size.y).is_greater_equal(720.0)
		if String(encounter.get("definition_id")) == "encounter_occupancy_dispute":
			police_count += 1
	assert_int(police_count).is_greater_equal(5)


func test_inactive_machine_platforms_are_not_used_to_ground_world_actors() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var supporting_ids: Array[String] = []
	for platform_value: Variant in builder._initially_supporting_platforms():
		supporting_ids.append(String((platform_value as Dictionary).get("id")))
	assert_bool("platform_ancom_overlook" in supporting_ids).is_true()
	for disabled_id: String in [
		"platform_restored_lift",
		"platform_final_crane", "platform_communal_hoist", "platform_final_dispatch_lift",
	]:
		assert_bool(disabled_id in supporting_ids).is_false()
	assert_bool("platform_egoist_bypass" in supporting_ids).is_true()
	assert_bool("platform_final_conveyor" in supporting_ids).is_true()
	assert_bool("platform_final_conveyor_secondary" in supporting_ids).is_true()


func test_egoist_cache_restores_health_and_resolves_without_machine_interaction() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var player := builder.get_node("Generated/Player") as PlayerController
	var health := player.get_node("Health") as HealthComponent
	assert_bool(health.damage(50.0)).is_true()
	var pickup := builder.get_node("Generated/Resources/pickup_egoist_health_cache") as DebugPickup
	var observer := builder.get_node("Generated/EncounterObservers/encounter_exclusion_corridor_raiders") as EncounterRuntimeObserver
	var gate := builder.get_node("Generated/Gates/gate_after_egoist_dispute") as AccessGate
	pickup._on_body_entered(player)
	assert_float(health.current_health).is_equal(85.0)
	assert_bool(pickup.is_collected()).is_true()
	assert_bool(observer.is_resolved()).is_true()
	assert_bool(gate.is_open()).is_true()


func test_final_gate_requires_police_ancom_egoist_and_mutualist_resolutions() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var gate := builder.get_node("Generated/Gates/gate_after_dispatch_police") as AccessGate
	var police := builder.get_node("Generated/EncounterObservers/encounter_dispatch_roadblock") as EncounterRuntimeObserver
	var truce := builder.get_node("Generated/RuleObjects/machine_final_truce_signal") as RuleStateObject
	var cache := builder.get_node("Generated/Resources/pickup_final_egoist_health_cache") as DebugPickup
	var reroute := builder.get_node("Generated/RuleObjects/machine_final_dispatch_reroute") as RuleStateObject
	var player := builder.get_node("Generated/Player") as PlayerController
	assert_bool(police.try_resolve(&"neutralize_enforcer")).is_true()
	assert_bool(gate.is_open()).is_false()
	assert_bool(truce.interact()).is_true()
	assert_bool(gate.is_open()).is_false()
	assert_bool(reroute.interact()).is_true()
	assert_bool(gate.is_open()).is_false()
	cache._on_body_entered(player)
	assert_bool(gate.is_open()).is_true()


func test_mutualist_machine_activates_a_visible_moving_elevator_without_blocking_ground_route() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var elevator := builder.get_node("Generated/Platforms/platform_restored_lift") as DebugPlatform
	var machine := builder.get_node("Generated/RuleObjects/machine_abandoned_lift") as RuleStateObject
	var origin_y := elevator.position.y
	assert_bool(elevator.is_moving_platform()).is_true()
	assert_bool(elevator.is_rule_enabled()).is_false()
	assert_bool(machine.interact()).is_true()
	elevator._physics_process(1.0)
	assert_float(elevator.position.y).is_less(origin_y)
	assert_object(elevator.get_node_or_null("ElevatorTop0")).is_not_null()


func test_first_ancom_challenge_reads_actor_then_machine_before_gate() -> void:
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data
	var ancom_x := 0.0
	var machine_x := 0.0
	var gate_x := 0.0
	for encounter_value: Variant in data.get("encounters", []) as Array:
		var encounter := encounter_value as Dictionary
		if String(encounter.get("id")) == "encounter_restored_output_raiders":
			ancom_x = float(encounter.get("x"))
	for machine_value: Variant in data.get("rule_objects", []) as Array:
		var machine := machine_value as Dictionary
		if String(machine.get("id")) == "machine_ancom_truce_one":
			machine_x = float(machine.get("x"))
	for gate_value: Variant in data.get("gates", []) as Array:
		var gate := gate_value as Dictionary
		if String(gate.get("id")) == "gate_after_ancom_patrol":
			gate_x = float(gate.get("x"))
	assert_float(ancom_x).is_greater(0.0)
	assert_float(ancom_x).is_less(machine_x)
	assert_float(machine_x).is_less(gate_x)
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	var access_platform := builder.get_node("Generated/Platforms/platform_ancom_overlook") as DebugPlatform
	var truce_machine := builder.get_node("Generated/RuleObjects/machine_ancom_truce_one") as RuleStateObject
	assert_bool(access_platform.is_rule_enabled()).is_true()
	assert_bool(truce_machine.interact()).is_true()


func test_first_elevator_places_its_reward_beyond_base_jump_and_at_upper_stop() -> void:
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data
	var elevator: Dictionary = {}
	var ground: Dictionary = {}
	var reward: Dictionary = {}
	for platform_value: Variant in data.get("platforms", []) as Array:
		var platform := platform_value as Dictionary
		match String(platform.get("id")):
			"platform_restored_lift": elevator = platform
			"ground_abandoned_lift": ground = platform
	for resource_value: Variant in data.get("resources", []) as Array:
		var resource := resource_value as Dictionary
		if String(resource.get("id")) == "pickup_restored_output":
			reward = resource
	var profile := load(String(data.get("movement_profile_path"))) as PlayerMovementProfile
	var base_jump_height := MovementMath.maximum_jump_height(profile)
	var elevator_upper_y := float(elevator.get("y")) + float(elevator.get("motion_distance_y"))
	assert_float(float(ground.get("y")) - float(reward.get("y"))).is_greater(base_jump_height * 1.5)
	assert_float(absf(float(reward.get("y")) - elevator_upper_y)).is_less_equal(24.0)
	assert_float(float(reward.get("x"))).is_between(
		float(elevator.get("x")),
		float(elevator.get("x")) + float(elevator.get("width"))
	)


func test_required_workshop_challenges_follow_problem_solution_gate_order() -> void:
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data
	var machines_by_id: Dictionary = {}
	var gates_by_id: Dictionary = {}
	for machine_value: Variant in data.get("rule_objects", []) as Array:
		var machine := machine_value as Dictionary
		machines_by_id[String(machine.get("id"))] = machine
	for gate_value: Variant in data.get("gates", []) as Array:
		var gate := gate_value as Dictionary
		gates_by_id[String(gate.get("id"))] = gate
	for encounter_value: Variant in data.get("encounters", []) as Array:
		var encounter := encounter_value as Dictionary
		if not bool(encounter.get("required_for_completion", false)):
			continue
		var gate_id := String(encounter.get("resolution_gate_id", ""))
		assert_bool(gates_by_id.has(gate_id)).is_true()
		var encounter_x := float(encounter.get("x"))
		var gate_x := float((gates_by_id[gate_id] as Dictionary).get("x"))
		assert_float(encounter_x).is_less(gate_x)
		for machine_id_value: Variant in encounter.get("rule_object_ids", []) as Array:
			var machine := machines_by_id[String(machine_id_value)] as Dictionary
			assert_float(float(machine.get("x"))).is_between(encounter_x, gate_x)


func test_abandoned_crane_reward_requires_its_enabled_platform() -> void:
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data
	var platform: Dictionary = {}
	var ground: Dictionary = {}
	var reward: Dictionary = {}
	for platform_value: Variant in data.get("platforms", []) as Array:
		var candidate := platform_value as Dictionary
		match String(candidate.get("id")):
			"platform_abandoned_crane": platform = candidate
			"ground_crane_choice": ground = candidate
	for resource_value: Variant in data.get("resources", []) as Array:
		var candidate := resource_value as Dictionary
		if String(candidate.get("id")) == "pickup_shared_spares":
			reward = candidate
	var profile := load(String(data.get("movement_profile_path"))) as PlayerMovementProfile
	var jump_height := MovementMath.maximum_jump_height(profile)
	assert_float(float(ground.get("y")) - float(reward.get("y"))).is_greater(jump_height * 1.5)
	assert_float(float(platform.get("y")) - float(reward.get("y"))).is_less(jump_height)
	assert_float(float(reward.get("x"))).is_between(
		float(platform.get("x")),
		float(platform.get("x")) + float(platform.get("width"))
	)


func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	return registry
