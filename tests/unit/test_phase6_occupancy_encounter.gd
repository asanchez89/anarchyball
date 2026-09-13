extends GdUnitTestSuite

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const PREVIEW_PATH := "res://data/levels/phase6_occupancy_preview.json"


func test_active_enemy_requires_declared_aggressor_reason() -> void:
	var archetype := EnemyArchetype.new()
	archetype.content_id = &"enemy_active_fixture"
	archetype.display_name = "Active fixture"
	archetype.actor_scene_path = "res://src/debug/combat_target.tscn"
	archetype.behavior_id = &"attack_player"

	assert_bool(archetype.is_structurally_valid()).is_false()
	archetype.aggressor_reason = ConflictStateComponent.AggressorReason.DETAIN_ORDER_EXECUTED
	assert_bool(archetype.is_structurally_valid()).is_true()


func test_occupancy_enforcer_and_encounter_are_registered_from_data() -> void:
	var registry := _registry()
	var archetype := registry.get_definition(ContentRegistry.Kind.ENEMY_ARCHETYPE, &"enemy_occupancy_enforcer") as EnemyArchetype
	var encounter := registry.get_definition(ContentRegistry.Kind.ENCOUNTER_DEFINITION, &"encounter_occupancy_dispute") as EncounterDefinition

	assert_object(archetype).is_not_null()
	assert_int(archetype.initial_conflict_state).is_equal(ConflictStateComponent.State.DISPUTED)
	assert_int(archetype.aggressor_reason).is_equal(ConflictStateComponent.AggressorReason.DETAIN_ORDER_EXECUTED)
	assert_str(archetype.threat_text).is_not_empty()
	assert_object(encounter).is_not_null()
	assert_array(encounter.allowed_resolutions).contains_exactly([&"neutralize_enforcer", &"operate_or_bypass_machine"])
	assert_str(encounter.neutralization_resolution).is_equal("neutralize_enforcer")
	assert_str(encounter.rule_interaction_resolution).is_equal("operate_or_bypass_machine")


func test_declared_reason_drives_disputed_threatening_aggressor_sequence() -> void:
	var root := Node2D.new()
	add_child(root)
	var actor := (load("res://src/debug/combat_target.tscn") as PackedScene).instantiate() as CombatTarget
	actor.apply_archetype(load("res://data/content/enemies/enemy_occupancy_enforcer.tres") as EnemyArchetype)
	root.add_child(actor)

	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.DISPUTED)
	assert_bool(actor.conflict_state.begin_threatening()).is_true()
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.THREATENING)
	assert_bool(actor.conflict_state.commit_aggression(actor.aggressor_reason)).is_true()
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
	assert_int(actor.conflict_state.aggressor_reason).is_equal(ConflictStateComponent.AggressorReason.DETAIN_ORDER_EXECUTED)
	root.free()


func test_rule_interaction_resolves_encounter_once_and_stops_pending_behavior() -> void:
	var root := Node2D.new()
	add_child(root)
	var actor := (load("res://src/debug/combat_target.tscn") as PackedScene).instantiate() as CombatTarget
	actor.apply_archetype(load("res://data/content/enemies/enemy_occupancy_enforcer.tres") as EnemyArchetype)
	root.add_child(actor)
	var machine := RuleStateObject.new()
	machine.current_state = RuleStateObject.State.AVAILABLE
	root.add_child(machine)
	var observer := EncounterRuntimeObserver.new()
	var events: Array[Dictionary] = []
	observer.resolved.connect(func(encounter_id: StringName, resolution: StringName) -> void:
		events.append({"encounter_id": encounter_id, "resolution": resolution})
	)
	observer.configure(
		&"occupancy_dispute",
		load("res://data/content/encounters/encounter_occupancy_dispute.tres") as EncounterDefinition,
		[actor],
		[machine]
	)
	root.add_child(observer)

	assert_bool(machine.interact()).is_true()
	assert_int(events.size()).is_equal(1)
	assert_str(events[0].get("encounter_id")).is_equal("occupancy_dispute")
	assert_str(events[0].get("resolution")).is_equal("operate_or_bypass_machine")
	assert_int(actor.behavior).is_equal(CombatTarget.Behavior.STATIC)
	actor.neutralized.emit(actor.stable_id)
	assert_int(events.size()).is_equal(1)
	root.free()


func test_neutralization_emits_declared_defensive_resolution_once() -> void:
	var root := Node2D.new()
	add_child(root)
	var actor := (load("res://src/debug/combat_target.tscn") as PackedScene).instantiate() as CombatTarget
	actor.apply_archetype(load("res://data/content/enemies/enemy_occupancy_enforcer.tres") as EnemyArchetype)
	root.add_child(actor)
	var observer := EncounterRuntimeObserver.new()
	var resolutions: Array[StringName] = []
	observer.resolved.connect(func(_encounter_id: StringName, resolution: StringName) -> void:
		resolutions.append(resolution)
	)
	observer.configure(
		&"occupancy_dispute",
		load("res://data/content/encounters/encounter_occupancy_dispute.tres") as EncounterDefinition,
		[actor],
		[]
	)
	root.add_child(observer)

	actor.neutralized.emit(actor.stable_id)
	actor.neutralized.emit(actor.stable_id)
	assert_array(resolutions).contains_exactly([&"neutralize_enforcer"])
	root.free()


func test_checkpoint_snapshot_can_reopen_an_unresolved_encounter() -> void:
	var observer := EncounterRuntimeObserver.new()
	var definition := load("res://data/content/encounters/encounter_occupancy_dispute.tres") as EncounterDefinition
	observer.configure(&"occupancy_dispute", definition, [], [])
	var unresolved_snapshot := observer.capture_runtime_state()

	assert_bool(observer.try_resolve(&"operate_or_bypass_machine")).is_true()
	assert_bool(observer.is_resolved()).is_true()
	observer.restore_runtime_state(unresolved_snapshot)
	assert_bool(observer.is_resolved()).is_false()
	assert_bool(observer.try_resolve(&"neutralize_enforcer")).is_true()
	observer.free()


func test_preview_links_encounter_to_declared_disputed_machine() -> void:
	var load_result := LevelSpecLoader.load_file(PREVIEW_PATH)
	var validation := LevelValidator.validate(load_result.spec, _registry())
	var placement := (load_result.spec.data.get("encounters") as Array)[0] as Dictionary

	assert_bool(validation.is_valid()).is_true()
	assert_str(placement.get("definition_id")).is_equal("encounter_occupancy_dispute")
	assert_array(placement.get("rule_object_ids") as Array).contains_exactly(["machine_disputed_use"])


func test_encounter_rejects_unknown_rule_object_reference() -> void:
	var load_result := LevelSpecLoader.load_file(PREVIEW_PATH)
	var data := load_result.spec.data.duplicate(true)
	var placement := (data.get("encounters") as Array)[0] as Dictionary
	placement["rule_object_ids"] = ["machine_missing"]
	var validation := LevelValidator.validate(LevelSpec.new(data, "res://fixture_unknown_encounter_rule_object.json"), _registry())

	assert_bool(_has_issue(validation, &"unknown_local_reference", "encounters[0].rule_object_ids[0]")).is_true()


func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	return registry


func _has_issue(validation: LevelValidationResult, code: StringName, field_path: String) -> bool:
	for issue: ValidationIssue in validation.issues:
		if issue.code == code and issue.field_path == field_path:
			return true
	return false
