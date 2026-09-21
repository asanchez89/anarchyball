extends GdUnitTestSuite

const LEVEL_PATH := "res://data/levels/w0_02_contract_bridge.json"
const PROFILE_PATH := "res://data/level_profiles/w0_02_contract_bridge.json"
const CATALOG_PATH := "res://data/content/default_catalog.tres"


func test_contract_definition_and_campaign_transition_are_registered() -> void:
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var registry := ContentRegistry.new()
	assert_bool(registry.register_catalog(catalog, CATALOG_PATH)).is_true()
	var definition := registry.get_definition(ContentRegistry.Kind.CONTRACT_DEFINITION, &"contract_bridge_access") as ContractDefinition
	var world := load("res://data/campaign/world_00_anarchist_frontier.tres") as WorldDefinition

	assert_object(definition).is_not_null()
	assert_bool(definition.is_structurally_valid()).is_true()
	assert_array(definition.allowed_resolutions).contains_exactly([&"reroute_bridge_control", &"bypass_and_exit"])
	assert_int(world.missions.size()).is_greater_equal(2)
	assert_str(world.missions[1].mission_id).is_equal("w0_02_contract_bridge")


func test_existing_completed_progress_reconciles_to_new_campaign_mission() -> void:
	var world := load("res://data/campaign/world_00_anarchist_frontier.tres") as WorldDefinition
	var progress := CampaignProgressState.new()
	progress.world_id = world.world_id
	progress.active_mission_id = &"w0_01_first_aggression"
	progress.completed_mission_ids = [&"w0_01_first_aggression"]
	progress.reconcile(world)

	assert_str(progress.active_mission_id).is_equal("w0_02_contract_bridge")


func test_contract_state_machine_changes_access_and_reveals_reward() -> void:
	var definition := load("res://data/content/contracts/contract_bridge_access.tres") as ContractDefinition
	var encounter := load("res://data/content/encounters/encounter_contract_breach.tres") as EncounterDefinition
	var entry_gate := auto_free(AccessGate.new()) as AccessGate
	var return_gate := auto_free(AccessGate.new()) as AccessGate
	var reward := auto_free(DebugPickup.new()) as DebugPickup
	var observer := auto_free(EncounterRuntimeObserver.new()) as EncounterRuntimeObserver
	observer.configure(&"encounter_fixture", encounter, [], [])
	var contract := auto_free(ContractRuntimeObject.new()) as ContractRuntimeObject
	contract.configure(&"contract_fixture", definition, null, entry_gate, return_gate, observer, null, reward, 500.0, Vector2(700.0, 500.0), 900.0)
	reward.set_available(false)

	assert_bool(contract.accept_contract()).is_true()
	assert_bool(entry_gate.is_open()).is_true()
	assert_bool(contract.mark_performed()).is_true()
	assert_bool(contract.commit_breach()).is_true()
	assert_int(contract.state).is_equal(ContractRuntimeObject.State.BREACHED)
	assert_bool(return_gate.is_open()).is_false()
	assert_bool(reward.is_available()).is_false()
	assert_bool(contract.resolve_breach(&"reroute_bridge_control")).is_true()
	assert_bool(return_gate.is_open()).is_true()
	assert_bool(reward.is_available()).is_true()
	assert_bool(observer.is_resolved()).is_true()


func test_contract_state_round_trips_for_checkpoint_restore() -> void:
	var definition := load("res://data/content/contracts/contract_bridge_access.tres") as ContractDefinition
	var contract := auto_free(ContractRuntimeObject.new()) as ContractRuntimeObject
	contract.configure(&"contract_fixture", definition, null, null, null, null, null, null, 500.0, Vector2.ZERO, 900.0)
	contract.accept_contract()
	contract.mark_performed()
	contract.commit_breach()
	var snapshot := contract.capture_runtime_state()
	var restored := auto_free(ContractRuntimeObject.new()) as ContractRuntimeObject
	restored.configure(&"contract_fixture", definition, null, null, null, null, null, null, 500.0, Vector2.ZERO, 900.0)

	assert_bool(restored.restore_runtime_state(snapshot)).is_true()
	assert_int(restored.state).is_equal(ContractRuntimeObject.State.BREACHED)


func test_egoist_contract_dispute_never_grants_offensive_permission() -> void:
	var archetype := load("res://data/content/enemies/npc_egoist_counterparty.tres") as EnemyArchetype
	var source := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	source.stable_id = &"player"
	source.authority = CombatIdentityComponent.Authority.PLAYER
	var identity := auto_free(CombatIdentityComponent.new()) as CombatIdentityComponent
	identity.stable_id = archetype.content_id
	var conflict := auto_free(ConflictStateComponent.new()) as ConflictStateComponent
	conflict.reset_conflict(archetype.initial_conflict_state)
	var resolve := auto_free(ResolveComponent.new()) as ResolveComponent
	resolve.maximum_resolve = archetype.maximum_resolve
	resolve.reset()
	var receiver := auto_free(EffectReceiverComponent.new()) as EffectReceiverComponent
	receiver.bind_for_test(identity, conflict, resolve)
	var permission := TargetValidity.evaluate(source, receiver, EffectContext.offensive())

	assert_int(archetype.initial_conflict_state).is_equal(ConflictStateComponent.State.DISPUTED)
	assert_bool(permission.allowed).is_false()
	assert_int(permission.decision).is_equal(TargetPermission.Decision.BLOCK_DISPUTED)


func test_egoist_prefers_early_surrender_after_committing_aggression() -> void:
	var archetype := load("res://data/content/enemies/npc_egoist_counterparty.tres") as EnemyArchetype
	var root := Node2D.new()
	add_child(root)
	var actor := (load("res://src/debug/combat_target.tscn") as PackedScene).instantiate() as CombatTarget
	actor.apply_archetype(archetype)
	root.add_child(actor)

	assert_int(archetype.defeat_response).is_equal(EnemyArchetype.DefeatResponse.SURRENDER)
	assert_float(archetype.surrender_resolve_ratio).is_equal_approx(0.65, 0.001)
	assert_float(actor.resolve.surrender_threshold).is_equal_approx(archetype.maximum_resolve * 0.65, 0.001)
	assert_bool(actor.conflict_state.begin_threatening()).is_true()
	assert_bool(actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ENCOUNTER_SCRIPT)).is_true()
	actor._on_surrender_threshold_reached()

	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.SURRENDERING)
	var source := CombatIdentityComponent.new()
	source.authority = CombatIdentityComponent.Authority.PLAYER
	assert_bool(TargetValidity.evaluate(source, actor.receiver, EffectContext.offensive()).allowed).is_false()
	source.free()
	root.free()


func test_contract_bridge_level_profile_and_runtime_validate() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	builder.start_in_menu = false
	add_child(builder)
	var validation := builder.build_from_file(LEVEL_PATH, load(CATALOG_PATH) as ContentCatalog)
	var profile_result := LevelPlaytestProfile.load_and_validate(PROFILE_PATH, PackedStringArray(["w0_02_contract_bridge"]))

	assert_bool(validation.is_valid()).is_true()
	assert_int((profile_result["errors"] as PackedStringArray).size()).is_equal(0)
	assert_object(builder.get_node_or_null("Generated/Contracts/contract_manifest_crossing")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Encounters/npc_egoist_counterparty")).is_not_null()
	assert_array(builder.required_unresolved_encounter_ids()).is_empty()


func test_contract_placement_rejects_unknown_gate_reference() -> void:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	var data := LevelSpecLoader.load_file(LEVEL_PATH).spec.data.duplicate(true)
	((data["contracts"] as Array)[0] as Dictionary)["resolution_gate_id"] = "missing_gate"
	var validation := LevelValidator.validate(LevelSpec.new(data, "res://invalid_contract_gate.json"), registry)
	var found := false
	for issue: ValidationIssue in validation.issues:
		found = found or (issue.code == &"unknown_local_reference" and issue.field_path == "contracts[0].resolution_gate_id")
	assert_bool(found).is_true()


func test_contract_telemetry_requires_explicit_transition_payload() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"w0_02_contract_bridge", &"class_contractor")
	assert_bool(telemetry.record_event(&"contract_state_changed", {"contract_id": "contract_manifest_crossing", "from_state": "offered", "to_state": "active"})).is_true()
	assert_bool(telemetry.record_event(&"contract_state_changed", {"contract_id": "contract_manifest_crossing"})).is_false()
