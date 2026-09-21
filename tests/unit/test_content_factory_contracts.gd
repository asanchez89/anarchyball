extends GdUnitTestSuite

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const VALID_SPEC := "res://data/levels/phase3_content_preview.json"
const LEVEL_PATHS: Array[String] = [
	"res://data/levels/occupancy_workshop_draft.json",
	"res://data/levels/mvp_hardening_variant.json",
	"res://data/levels/mvp_vertical_slice.json",
	"res://data/levels/phase3_content_preview.json",
	"res://data/levels/phase6_occupancy_preview.json",
]


func test_current_catalog_and_level_batch_is_valid() -> void:
	var errors := ContentBatchValidator.validate(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH, PackedStringArray(LEVEL_PATHS))
	assert_array(errors).is_empty()


func test_batch_rejects_unreferenced_definition_with_unknown_hook() -> void:
	var catalog := (load(CATALOG_PATH) as ContentCatalog).duplicate(true) as ContentCatalog
	var unsupported_rule := IdeologyRuleDefinition.new()
	unsupported_rule.content_id = &"rule_unsupported_hook"
	unsupported_rule.display_name = "Unsupported hook fixture"
	unsupported_rule.hook_id = &"execute_arbitrary_script"
	unsupported_rule.counterplay_tags = [&"baseline_bypass"]
	catalog.ideology_rules.append(unsupported_rule)

	var errors := ContentBatchValidator.validate(catalog, "res://fixture_catalog.tres", PackedStringArray())
	assert_bool(_contains_error(errors, "ideology_rules[2].hook_id", "unsupported_rule_hook")).is_true()


func test_rule_object_contract_accepts_supported_hook_and_local_target() -> void:
	var modified := _valid_data()
	modified["rule_objects"] = [{
		"id": "rule_object_fixture",
		"hook_id": "access_gate",
		"x": 200,
		"y": 550,
		"initial_state": "available",
		"target_platform_ids": ["platform_start"],
		"interaction_tag": "baseline_bypass",
	}]
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_rule_object.json"), _registry())
	assert_bool(validation.is_valid()).is_true()


func test_rule_object_rejects_unknown_platform_reference() -> void:
	var modified := _valid_data()
	modified["rule_objects"] = [{
		"id": "rule_object_fixture",
		"hook_id": "access_gate",
		"x": 200,
		"y": 550,
		"initial_state": "available",
		"target_platform_ids": ["platform_missing"],
		"interaction_tag": "baseline_bypass",
	}]
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_rule_target.json"), _registry())
	assert_bool(_has_issue(validation, &"unknown_local_reference", "rule_objects[0].target_platform_ids[0]")).is_true()


func test_rule_object_requires_active_rule_valid_state_targets_and_counterplay() -> void:
	var modified := _valid_data()
	modified["ideology_rule_ids"] = []
	modified["rule_objects"] = [{
		"id": "rule_object_fixture",
		"hook_id": "access_gate",
		"x": 200,
		"y": 550,
		"initial_state": "arbitrary",
		"target_platform_ids": [],
		"interaction_tag": "unknown_interaction",
	}]
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_invalid_rule_object.json"), _registry())
	assert_bool(_has_issue(validation, &"rule_hook_mismatch", "rule_objects[0].hook_id")).is_true()
	assert_bool(_has_issue(validation, &"invalid_rule_state", "rule_objects[0].initial_state")).is_true()
	assert_bool(_has_issue(validation, &"missing_targets", "rule_objects[0].target_platform_ids")).is_true()


func test_duplicate_ids_across_level_collections_are_rejected() -> void:
	var modified := _valid_data()
	(modified["resources"] as Array).append({
		"id": "platform_start",
		"kind": "training_supply",
		"x": 100,
		"y": 550,
		"ownership": "unowned_collectible",
	})
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_duplicate_id.json"), _registry())
	assert_bool(_has_issue(validation, &"duplicate_local_id", "resources[1].id")).is_true()


func test_unknown_levelspec_field_is_rejected() -> void:
	var modified := _valid_data()
	modified["arbitrary_script"] = "res://do_not_execute.gd"
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_unknown_field.json"), _registry())
	assert_bool(_has_issue(validation, &"unknown_field", "arbitrary_script")).is_true()


func test_nested_unknown_field_is_rejected() -> void:
	var modified := _valid_data()
	var platform := (modified["platforms"] as Array)[0] as Dictionary
	platform["script"] = "res://do_not_execute.gd"
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_nested_field.json"), _registry())
	assert_bool(_has_issue(validation, &"unknown_field", "platforms[0].script")).is_true()


func test_platform_art_style_rejects_unknown_visual_construction() -> void:
	var modified := _valid_data()
	var platform := (modified["platforms"] as Array)[0] as Dictionary
	platform["art_style"] = "floating_wall"
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_platform_art.json"), _registry())
	assert_bool(_has_issue(validation, &"invalid_platform_art_style", "platforms[0].art_style")).is_true()


func test_level_geometry_and_sections_must_stay_inside_bounds() -> void:
	var modified := _valid_data()
	var platform := (modified["platforms"] as Array)[0] as Dictionary
	var section := (modified["sections"] as Array)[0] as Dictionary
	platform["width"] = 2000
	section["to_x"] = 2000
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_bounds.json"), _registry())
	assert_bool(_has_issue(validation, &"geometry_out_of_bounds", "platforms[0]")).is_true()
	assert_bool(_has_issue(validation, &"section_out_of_bounds", "sections[0]")).is_true()


func _valid_data() -> Dictionary:
	return LevelSpecLoader.load_file(VALID_SPEC).spec.data.duplicate(true)


func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	return registry


func _has_issue(validation: LevelValidationResult, code: StringName, field_path: String) -> bool:
	for issue: ValidationIssue in validation.issues:
		if issue.code == code and issue.field_path == field_path:
			return true
	return false


func _contains_error(errors: PackedStringArray, field_path: String, code: String) -> bool:
	for error: String in errors:
		if field_path in error and code in error:
			return true
	return false
