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
	actor.set_process(false)
	var floor_body := auto_free(StaticBody2D.new()) as StaticBody2D
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(500, 20)
	floor_shape.shape = rectangle
	floor_body.position = Vector2(0, 34)
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	await get_tree().physics_frame
	await get_tree().physics_frame
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
		630.0,
		builder.art_surface_depth,
		WorldPropPlacement.BALL_ORIGIN_TO_FLOOR
	)
	assert_float(raider.position.y).is_equal(expected.y)



func test_police_detects_at_longer_range_without_skipping_the_warning() -> void:
	var builder := _build()
	var police := builder.get_node("Generated/Encounters/enemy_occupancy_enforcer") as CombatTarget
	assert_float(police.activation_distance).is_equal(600.0)
	builder._player.global_position = police.global_position - Vector2(601.0, 0.0)
	police._update_behavior(3.0)
	assert_float(police._behavior_elapsed).is_equal(0.0)
	assert_bool(police._aggression_committed).is_false()
	builder._player.global_position = police.global_position - Vector2(550.0, 0.0)
	police._update_behavior(0.9)
	assert_int(police.conflict_state.current_state).is_equal(ConflictStateComponent.State.THREATENING)
	assert_bool(police._aggression_committed).is_false()
	police._update_behavior(2.0)
	assert_int(police.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
	assert_bool(police._aggression_committed).is_true()


func test_police_projectile_deals_five_health_without_changing_other_archetypes() -> void:
	var builder := _build()
	var police := builder.get_node("Generated/Encounters/enemy_occupancy_enforcer") as CombatTarget
	assert_float(police.projectile_damage).is_equal(5.0)
	assert_float(EnemyArchetype.new().projectile_damage).is_equal(10.0)
	police._launch_bolt_direction(Vector2.LEFT)
	var bolt: HostileBolt
	for child: Node in police.get_parent().get_children():
		if child is HostileBolt:
			bolt = child as HostileBolt
	assert_object(bolt).is_not_null()
	assert_float(bolt.damage_amount).is_equal(5.0)
	var health := builder._player.get_node("Health") as HealthComponent
	var before := health.current_health
	bolt._on_body_entered(builder._player)
	assert_float(health.current_health).is_equal(before - 5.0)


func test_archetype_rejects_invalid_projectile_damage() -> void:
	var archetype := (load("res://data/content/enemies/enemy_occupancy_enforcer.tres") as EnemyArchetype).duplicate() as EnemyArchetype
	assert_bool(archetype.is_structurally_valid()).is_true()
	archetype.projectile_damage = -1.0
	assert_bool(archetype.is_structurally_valid()).is_false()
	archetype.projectile_damage = NAN
	assert_bool(archetype.is_structurally_valid()).is_false()


func test_projectile_passes_surrendered_balls_and_hits_next_aggressor_once() -> void:
	var builder := _build()
	var target := builder.get_node("Generated/Encounters/enemy_occupancy_enforcer") as CombatTarget
	var source := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	source.authority = CombatIdentityComponent.Authority.PLAYER
	source.stable_id = &"player"
	var probe := load("res://src/combat/sandbox/aim_probe.tscn").instantiate() as AimProbe
	builder.add_child(probe)
	probe.configure(Vector2.RIGHT, source, EffectContext.offensive())
	var before := target.resolve.current_resolve
	for state: ConflictStateComponent.State in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
		target.conflict_state.reset_conflict(state)
		probe._on_area_entered(target)
		assert_bool(probe.is_queued_for_deletion()).is_false()
		assert_float(target.resolve.current_resolve).is_equal(before)
	var next_target := load("res://src/debug/combat_target.tscn").instantiate() as CombatTarget
	builder.add_child(next_target)
	next_target.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	var next_before := next_target.resolve.current_resolve
	probe._on_area_entered(next_target)
	assert_bool(probe.is_queued_for_deletion()).is_true()
	assert_float(next_target.resolve.current_resolve).is_equal(next_before - probe.effect_amount)
	probe._on_area_entered(next_target)
	assert_float(next_target.resolve.current_resolve).is_equal(next_before - probe.effect_amount)


func _build() -> LevelBuilder:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	assert_bool(builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog).is_valid()).is_true()
	return builder


func test_five_areas_have_only_reception_and_dispatch_as_mandatory_closures() -> void:
	var builder := _build()
	assert_int((builder.loaded_spec.data["sections"] as Array).size()).is_equal(5)
	assert_int((builder.loaded_spec.data["gates"] as Array).size()).is_equal(2)
	assert_int((builder.loaded_spec.data["checkpoints"] as Array).size()).is_equal(2)
	assert_array(builder.required_unresolved_encounter_ids()).contains_exactly([
		&"encounter_arrival_scout", &"encounter_dispatch_roadblock",
	])
	var profile := LevelPlaytestProfile.load_and_validate(PROFILE_PATH, PackedStringArray(["w0_03_occupancy_workshop"]))
	assert_int((profile["errors"] as PackedStringArray).size()).is_equal(0)


func test_upper_control_requires_feeder_and_lift_can_be_recalled() -> void:
	var builder := _build()
	var control := builder.get_node("Generated/RuleObjects/control_production_transfer") as RuleStateObject
	var feeder := builder.get_node("Generated/RuleObjects/machine_production_feeder") as RuleStateObject
	var call_button := builder.get_node("Generated/RuleObjects/call_production_lift") as RuleStateObject
	var lift := builder.get_node("Generated/Platforms/platform_restored_lift") as DebugPlatform
	var bridge := builder.get_node("Generated/Platforms/production_transfer") as DebugPlatform
	assert_bool(control.interact()).is_false()
	assert_bool(call_button.interact()).is_false()
	assert_bool(lift.is_rule_enabled()).is_false()
	assert_bool(bridge.is_rule_enabled()).is_false()
	assert_str(control.guidance_text()).contains("SIN ALIMENTACIÓN")
	assert_bool(feeder.interact()).is_true()
	assert_bool(lift.is_rule_enabled()).is_true()
	assert_bool(control.interact()).is_true()
	assert_bool(bridge.is_rule_enabled()).is_true()
	assert_bool(call_button.interact()).is_true()
	assert_bool(lift.is_rule_enabled()).is_true()


func test_truce_and_defensive_surrender_both_release_service_walkway() -> void:
	for use_truce: bool in [true, false]:
		var builder := _build()
		var observer := builder.get_node("Generated/EncounterObservers/encounter_depot_patrol") as EncounterRuntimeObserver
		var bridge := builder.get_node("Generated/Platforms/depot_service_walkway") as DebugPlatform
		assert_bool(bridge.is_rule_enabled()).is_false()
		if use_truce:
			assert_bool((builder.get_node("Generated/RuleObjects/signal_depot_truce") as RuleStateObject).interact()).is_true()
		else:
			for actor: CombatTarget in observer._actors:
				actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
				actor.conflict_state.neutralize()
		assert_bool(observer.is_resolved()).is_true()
		assert_bool(bridge.is_rule_enabled()).is_true()


func test_withdrawing_from_warning_clears_timer_without_committing_aggression() -> void:
	var builder := _build()
	var observer := builder.get_node("Generated/EncounterObservers/encounter_depot_patrol") as EncounterRuntimeObserver
	var actor := observer._actors[0]
	var player := builder.get_node("Generated/Player") as PlayerController
	player.position = actor.position + Vector2(40, 0)
	actor._update_behavior(1.0)
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.THREATENING)
	player.position.x -= 500.0
	actor._update_behavior(0.1)
	assert_int(actor.conflict_state.current_state).is_equal(actor.initial_state)
	assert_float(actor._behavior_elapsed).is_equal(0.0)


func test_egoist_permits_recovery_and_cache_provides_real_health() -> void:
	var builder := _build()
	var observer := builder.get_node("Generated/EncounterObservers/encounter_storage_cache") as EncounterRuntimeObserver
	var player := builder.get_node("Generated/Player") as PlayerController
	var health := player.get_node("Health") as HealthComponent
	var cache := builder.get_node("Generated/Resources/pickup_storage_health") as DebugPickup
	var actor := observer._actors[0]
	player.position = actor.position
	actor._update_behavior(20.0)
	assert_int(actor.behavior).is_equal(CombatTarget.Behavior.STATIC)
	assert_int(actor.conflict_state.current_state).is_not_equal(ConflictStateComponent.State.AGGRESSOR)
	assert_str(cache.ownership).is_equal("permitted_salvage")
	health.restore(40.0)
	cache._on_body_entered(player)
	assert_float(health.current_health).is_equal(75.0)
	assert_bool(observer.is_resolved()).is_true()
	cache._on_body_entered(player)
	assert_float(health.current_health).is_equal(75.0)


func test_dispatch_escape_works_under_fire_without_requiring_truce_or_cache() -> void:
	var builder := _build()
	var observer := builder.get_node("Generated/EncounterObservers/encounter_dispatch_roadblock") as EncounterRuntimeObserver
	var gate := builder.get_node("Generated/Gates/gate_dispatch") as AccessGate
	for actor: CombatTarget in observer._actors:
		actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	var control := builder.get_node("Generated/RuleObjects/control_dispatch_exit") as RuleStateObject
	assert_bool(control.interact()).is_false()
	assert_bool((builder.get_node("Generated/RuleObjects/machine_dispatch_feeder") as RuleStateObject).interact()).is_true()
	assert_bool(control.interact()).is_true()
	assert_bool(gate.is_open()).is_true()
	assert_bool(observer.is_resolved()).is_true()
	for actor: CombatTarget in observer._actors:
		assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
	assert_bool((builder.get_node("Generated/Resources/pickup_dispatch_health") as DebugPickup).is_collected()).is_false()
	assert_array(builder.required_unresolved_encounter_ids()).contains_exactly([&"encounter_arrival_scout"])


func test_combat_resolution_removes_actual_reception_and_dispatch_barriers() -> void:
	var builder := _build()
	for pair: Array in [["encounter_arrival_scout", "gate_reception"], ["encounter_dispatch_roadblock", "gate_dispatch"]]:
		var observer := builder.get_node("Generated/EncounterObservers/" + String(pair[0])) as EncounterRuntimeObserver
		var gate := builder.get_node("Generated/Gates/" + String(pair[1])) as AccessGate
		assert_bool(gate.is_open()).is_false()
		for actor: CombatTarget in observer._actors:
			actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
			actor.conflict_state.neutralize()
		await get_tree().process_frame
		await get_tree().process_frame
		assert_bool(gate.is_open()).is_true()
		assert_bool(gate.is_collision_enabled()).is_false()
	assert_array(builder.required_unresolved_encounter_ids()).is_empty()


func test_checkpoint_restores_unresolved_patrol_and_releases_again_on_truce() -> void:
	var builder := _build()
	var signal_control := builder.get_node("Generated/RuleObjects/signal_depot_truce") as RuleStateObject
	var observer := builder.get_node("Generated/EncounterObservers/encounter_depot_patrol") as EncounterRuntimeObserver
	var bridge := builder.get_node("Generated/Platforms/depot_service_walkway") as DebugPlatform
	builder.activate_checkpoint(&"test_before_truce", Vector2(4300, 620))
	signal_control.interact()
	assert_bool(bridge.is_rule_enabled()).is_true()
	assert_int(observer._actors[0].behavior).is_equal(CombatTarget.Behavior.STATIC)
	builder.retry_from_checkpoint()
	assert_bool(bridge.is_rule_enabled()).is_false()
	assert_bool(observer.is_resolved()).is_false()
	assert_int(observer._actors[0].behavior).is_equal(CombatTarget.Behavior.ATTACK_PLAYER)
	signal_control.interact()
	builder.activate_checkpoint(&"test_after_truce", Vector2(6400, 620))
	builder.retry_from_checkpoint()
	assert_bool(bridge.is_rule_enabled()).is_true()


func test_checkpoint_mid_combat_does_not_lose_previously_neutralized_actor() -> void:
	var builder := _build()
	var observer := builder.get_node("Generated/EncounterObservers/encounter_dispatch_roadblock") as EncounterRuntimeObserver
	observer._actors[0].conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	observer._actors[0].conflict_state.neutralize()
	builder.activate_checkpoint(&"test_partial", Vector2(10060, 590))
	builder.retry_from_checkpoint()
	observer._actors[1].conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	observer._actors[1].conflict_state.neutralize()
	assert_bool(observer.is_resolved()).is_true()


func test_invalid_and_cyclic_machine_dependencies_are_rejected() -> void:
	for dependency: String in ["missing_control", "control_production_transfer"]:
		var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data.duplicate(true)
		for machine: Dictionary in data["rule_objects"]:
			if machine["id"] == "machine_production_feeder":
				machine["requires"] = [dependency]
		assert_bool(LevelValidator.validate(LevelSpec.new(data, "test"), _registry()).is_valid()).is_false()


func test_locked_and_moving_platforms_never_ground_stationary_actors() -> void:
	var builder := _build()
	var supporting_ids: Array[String] = []
	for platform: Dictionary in builder._initially_supporting_platforms():
		supporting_ids.append(String(platform["id"]))
	assert_bool("depot_service_walkway" in supporting_ids).is_false()
	assert_bool("dispatch_lift" in supporting_ids).is_false()
	assert_bool("production_transfer" in supporting_ids).is_false()


func test_elevator_art_matches_full_physics_width_including_partial_last_tile() -> void:
	var lift := auto_free(DebugPlatform.new()) as DebugPlatform
	lift.size = Vector2(300, 24)
	lift.collision_surface_depth = 32
	lift.configure_motion(-180, 64, load("res://assets/art/world_0/frontier_forest/tileset.png") as Texture2D)
	add_child(lift)
	var visible_right := -INF
	for child: Node in lift.get_children():
		if child is Sprite2D:
			var sprite := child as Sprite2D
			visible_right = maxf(visible_right, sprite.position.x + sprite.texture.get_width() * sprite.scale.x)
	assert_float(visible_right).is_equal_approx(150.0, 0.01)
	assert_bool((lift.get_child(0) as CollisionShape2D).one_way_collision).is_true()


class RidingProbe extends CharacterBody2D:
	func _physics_process(delta: float) -> void:
		velocity.y += 1800.0 * delta
		move_and_slide()


func test_lift_carries_a_physics_body_through_ascent() -> void:
	var lift := auto_free(DebugPlatform.new()) as DebugPlatform
	lift.size = Vector2(288, 24)
	lift.position = Vector2(600, 600)
	lift.configure_motion(-180, 64)
	add_child(lift)
	var rider := auto_free(RidingProbe.new()) as RidingProbe
	rider.position = Vector2(600, 562)
	rider.collision_layer = 2
	rider.collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(46, 48)
	shape_node.shape = shape
	rider.add_child(shape_node)
	add_child(rider)
	await get_tree().create_timer(2.3).timeout
	assert_bool(rider.is_on_floor()).is_true()
	assert_float(rider.position.y).is_less(510.0)
	assert_float(absf(rider.position.y + 24.0 - (lift.position.y - 12.0))).is_less(3.0)


func test_workshop_presentation_loads_authored_assets_and_grounded_stations() -> void:
	var scene := load("res://levels/world_0/presentation/world0_workshop_presentation.tscn") as PackedScene
	var presentation := auto_free(scene.instantiate()) as Node2D
	add_child(presentation)
	presentation.call("configure", LevelSpecLoader.load_file(LEVEL_PATH).spec)
	assert_int(presentation.get_node("WorkshopStations").get_child_count()).is_greater(20)
	assert_object(presentation.get_node_or_null("TerrainArt/platform_restored_liftGuide00_0")).is_not_null()
	for child: Node in presentation.get_node("WorkshopStations").get_children():
		if child is Sprite2D:
			assert_object((child as Sprite2D).texture).is_not_null()


func test_scene_keeps_terrain_behind_actors_and_marks_inactive_surfaces() -> void:
	var scene := load("res://levels/world_0/w0_03_occupancy_workshop.tscn") as PackedScene
	var builder := auto_free(scene.instantiate()) as LevelBuilder
	builder.start_in_menu = false
	add_child(builder)
	var presentation := builder.get_node("Generated/Presentation") as Node2D
	var terrain := presentation.get_node("TerrainArt") as Node2D
	assert_int(presentation.z_index + terrain.z_index).is_less(0)
	var platform := builder.get_node("Generated/Platforms/production_transfer") as DebugPlatform
	assert_int(platform.surface_art.size()).is_greater(0)
	assert_float(platform.surface_art[0].modulate.a).is_less(0.3)
	platform.set_rule_enabled(true)
	assert_float(platform.surface_art[0].modulate.a).is_equal_approx(1.0, 0.01)


func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	assert_bool(registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)).is_true()
	return registry
