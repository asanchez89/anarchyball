extends GdUnitTestSuite

const SLICE_SPEC := "res://data/levels/mvp_vertical_slice.json"
const CATALOG_PATH := "res://data/content/default_catalog.tres"


func test_checkpoint_state_round_trips_versioned_explicit_data() -> void:
	var original := RunCheckpointState.new()
	original.capture(
		&"checkpoint_before_commander",
		Vector2(2740.0, 570.0),
		100.0,
		{"enemy_guard_aggressor": {"conflict_state": 3, "resolve": 20.0}},
		[&"pickup_frontier_supply"],
		{"gate_voluntary_access": true}
	)
	var restored := RunCheckpointState.from_dictionary(original.to_dictionary(&"mvp_vertical_slice"))

	assert_object(restored).is_not_null()
	assert_str(restored.checkpoint_id).is_equal("checkpoint_before_commander")
	assert_bool(restored.player_position.is_equal_approx(Vector2(2740.0, 570.0))).is_true()
	assert_bool(bool(restored.world_rule_state.get("gate_voluntary_access"))).is_true()


func test_unknown_checkpoint_schema_is_rejected() -> void:
	assert_object(RunCheckpointState.from_dictionary({"schema_version": 99, "player_position": {"x": 0, "y": 0}})).is_null()


func test_defensive_response_temporarily_modifies_weapon() -> void:
	var player := auto_free((load("res://src/actors/player/player.tscn") as PackedScene).instantiate()) as PlayerController
	add_child(player)
	var response := ContractorDefensiveResponse.new()
	response.profile = load("res://data/classes/defensive_response_profile.tres") as DefensiveResponseProfile
	player.add_child(response)
	var launcher := player.get_node("ProbeLauncher") as SandboxProbeLauncher

	response.activate(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	assert_bool(response.is_active()).is_true()
	assert_float(launcher.cooldown_multiplier).is_less(1.0)
	assert_float(launcher.effect_amount_multiplier).is_greater(1.0)
	response.reset()
	assert_float(launcher.cooldown_multiplier).is_equal(1.0)


func test_vertical_slice_validates_and_builds_required_runtime() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	var validation := builder.build_from_file(SLICE_SPEC, load(CATALOG_PATH) as ContentCatalog)

	assert_bool(validation.is_valid()).is_true()
	assert_object(builder.get_node_or_null("Generated/Player/ContractorDefensiveResponse")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Encounters/npc_merchant_neutral")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Encounters/enemy_checkpoint_commander")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Gates/gate_voluntary_access")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Checkpoints/checkpoint_before_commander")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Flow")).is_not_null()


func test_checkpoint_restores_actor_resolve_and_conflict_state() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	builder.build_from_file(SLICE_SPEC, load(CATALOG_PATH) as ContentCatalog)
	var actor := builder.get_node("Generated/Encounters/enemy_guard_aggressor") as CombatTarget
	actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	actor.resolve.reduce(10.0)
	builder.activate_checkpoint(&"test_checkpoint", Vector2(700.0, 500.0))
	actor.resolve.reduce(20.0)
	actor.conflict_state.neutralize()

	builder.retry_from_checkpoint()
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
	assert_float(actor.resolve.current_resolve).is_equal(20.0)
	assert_bool(builder._player.global_position.is_equal_approx(Vector2(700.0, 500.0))).is_true()


func test_boss_definition_declares_legitimacy_adaptation_and_resolutions() -> void:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	var encounter := registry.get_definition(ContentRegistry.Kind.ENCOUNTER_DEFINITION, &"encounter_checkpoint_commander") as EncounterDefinition
	var boss := registry.get_definition(ContentRegistry.Kind.ENEMY_ARCHETYPE, &"enemy_checkpoint_commander") as EnemyArchetype

	assert_bool(encounter.is_boss).is_true()
	assert_bool(encounter.aggression_trigger_ids.is_empty()).is_false()
	assert_int(encounter.allowed_resolutions.size()).is_greater_equal(2)
	assert_bool(boss.is_boss).is_true()
	assert_float(boss.phase_two_ratio).is_between(0.1, 0.9)
