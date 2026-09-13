extends GdUnitTestSuite

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const PREVIEW_PATH := "res://data/levels/phase6_occupancy_preview.json"


func test_occupancy_rule_is_registered_with_runtime_hook_and_counterplay() -> void:
	var registry := ContentRegistry.new()
	assert_bool(registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)).is_true()
	var rule := registry.get_definition(ContentRegistry.Kind.IDEOLOGY_RULE, &"rule_occupancy_and_use") as IdeologyRuleDefinition

	assert_object(rule).is_not_null()
	assert_str(rule.hook_id).is_equal("occupancy_machine")
	assert_array(rule.counterplay_tags).contains([&"occupy_machine", &"baseline_bypass"])


func test_available_machine_becomes_occupied_and_enables_only_its_targets() -> void:
	var root := Node2D.new()
	add_child(root)
	var target := DebugPlatform.new()
	root.add_child(target)
	var untouched := DebugPlatform.new()
	root.add_child(untouched)
	var machine := RuleStateObject.new()
	machine.rule_id = &"rule_occupancy_and_use"
	machine.object_id = &"machine_fixture"
	machine.interaction_tag = &"occupy_machine"
	machine.current_state = RuleStateObject.State.AVAILABLE
	machine.configure_targets([target])
	root.add_child(machine)

	assert_bool(target.is_rule_enabled()).is_false()
	assert_bool(untouched.is_rule_enabled()).is_true()
	assert_bool(machine.interact()).is_true()
	assert_int(machine.current_state).is_equal(RuleStateObject.State.OCCUPIED)
	assert_bool(target.is_rule_enabled()).is_true()
	assert_bool(untouched.is_rule_enabled()).is_true()
	assert_bool(machine.interact()).is_false()
	root.free()


func test_preview_declares_two_real_machines_and_a_baseline_route() -> void:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	var load_result := LevelSpecLoader.load_file(PREVIEW_PATH)
	var validation := LevelValidator.validate(load_result.spec, registry)
	var rule_objects := load_result.spec.data.get("rule_objects") as Array
	var required_platforms := (load_result.spec.data.get("platforms") as Array).filter(
		func(platform: Variant) -> bool: return bool((platform as Dictionary).get("required", true))
	)

	assert_bool(validation.is_valid()).is_true()
	assert_int(rule_objects.size()).is_equal(2)
	assert_int(required_platforms.size()).is_equal(2)
	assert_object(load("res://levels/prototypes/occupancy_rule_preview.tscn") as PackedScene).is_not_null()


func test_checkpoint_restores_machine_and_platform_state() -> void:
	var root := Node2D.new()
	add_child(root)
	var target := DebugPlatform.new()
	root.add_child(target)
	var machine := RuleStateObject.new()
	machine.current_state = RuleStateObject.State.AVAILABLE
	machine.configure_targets([target])
	root.add_child(machine)
	machine.interact()
	var saved_state := machine.capture_runtime_state()
	machine.transition_to(RuleStateObject.State.AVAILABLE)

	assert_bool(target.is_rule_enabled()).is_false()
	assert_bool(machine.restore_runtime_state(saved_state)).is_true()
	assert_int(machine.current_state).is_equal(RuleStateObject.State.OCCUPIED)
	assert_bool(target.is_rule_enabled()).is_true()
	root.free()
