extends GdUnitTestSuite

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const VALID_SPEC := "res://data/levels/phase3_content_preview.json"
const IMPOSSIBLE_SPEC := "res://tests/fixtures/levels/impossible_gap_level.json"


func test_valid_fixture_loads_and_passes_validation() -> void:
	var load_result := LevelSpecLoader.load_file(VALID_SPEC)
	assert_bool(load_result.is_success()).is_true()
	var validation := LevelValidator.validate(load_result.spec, _registry())
	assert_bool(validation.is_valid()).is_true()


func test_impossible_gap_is_rejected_with_actionable_field() -> void:
	var load_result := LevelSpecLoader.load_file(IMPOSSIBLE_SPEC)
	var validation := LevelValidator.validate(load_result.spec, _registry())

	assert_bool(validation.is_valid()).is_false()
	assert_bool(_has_issue(validation, &"unreachable_required_route", "platforms")).is_true()
	assert_bool(validation.formatted_errors()[0].contains(IMPOSSIBLE_SPEC)).is_true()


func test_unknown_reference_reports_exact_field() -> void:
	var original := LevelSpecLoader.load_file(VALID_SPEC).spec
	var modified := original.data.duplicate(true)
	modified["class_loadout_id"] = "class_missing"
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_unknown.json"), _registry())

	assert_bool(_has_issue(validation, &"unknown_reference", "class_loadout_id")).is_true()
	assert_bool("\n".join(validation.formatted_errors()).contains("class_missing")).is_true()


func test_missing_mandatory_field_fails_before_runtime_build() -> void:
	var original := LevelSpecLoader.load_file(VALID_SPEC).spec
	var modified := original.data.duplicate(true)
	modified.erase("exit")
	var validation := LevelValidator.validate(LevelSpec.new(modified, "res://fixture_missing.json"), _registry())

	assert_bool(_has_issue(validation, &"missing_field", "exit")).is_true()


func test_builder_creates_playable_nodes_from_valid_data() -> void:
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	add_child(builder)
	var validation := builder.build_from_file(VALID_SPEC, load(CATALOG_PATH) as ContentCatalog)

	assert_bool(validation.is_valid()).is_true()
	assert_object(builder.get_node_or_null("Generated/Player")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Platforms/platform_start")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Encounters/enemy_guard_aggressor")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Exit")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/RunTelemetry")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Hud")).is_not_null()
	assert_object(builder.get_node_or_null("Generated/Platforms/platform_optionalRoute")).is_not_null()


func test_ideology_rule_data_changes_generated_variant() -> void:
	var catalog := (load(CATALOG_PATH) as ContentCatalog).duplicate(true) as ContentCatalog
	var rule := catalog.ideology_rules[0]
	rule.parameters = rule.parameters.duplicate(true)
	rule.parameters["primary_color"] = "4a214f"
	var builder := auto_free(LevelBuilder.new()) as LevelBuilder
	builder.build_on_ready = false
	add_child(builder)
	builder.build_from_file(VALID_SPEC, catalog)
	var backdrop := builder.get_node("Generated/Backdrop") as Polygon2D

	assert_bool(backdrop.color.is_equal_approx(Color("4a214f"))).is_true()


func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	return registry


func _has_issue(validation: LevelValidationResult, code: StringName, field_path: String) -> bool:
	for issue: ValidationIssue in validation.issues:
		if issue.code == code and issue.field_path == field_path:
			return true
	return false
