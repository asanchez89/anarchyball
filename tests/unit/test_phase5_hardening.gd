extends GdUnitTestSuite

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const VARIANT_PATH := "res://data/levels/mvp_hardening_variant.json"


func test_accessibility_settings_round_trip_and_reject_unknown_schema() -> void:
	var settings := AccessibilitySettings.new()
	settings.screen_shake_enabled = false
	settings.subtitles_enabled = false
	settings.ui_scale = 1.3
	var restored := AccessibilitySettings.from_dictionary(settings.to_dictionary())

	assert_bool(restored.screen_shake_enabled).is_false()
	assert_bool(restored.subtitles_enabled).is_false()
	assert_float(restored.ui_scale).is_equal(1.3)
	var fallback := AccessibilitySettings.from_dictionary({"schema_version": 99, "ui_scale": 9.0})
	assert_float(fallback.ui_scale).is_equal(1.0)


func test_accessibility_scale_cycles_only_supported_values() -> void:
	var settings := AccessibilitySettings.new()
	assert_float(settings.cycle_ui_scale()).is_equal(1.15)
	assert_float(settings.cycle_ui_scale()).is_equal(1.3)
	assert_float(settings.cycle_ui_scale()).is_equal(1.0)


func test_balance_summary_extracts_regression_signals() -> void:
	var summary := TelemetryBalanceSummary.summarize({
		"elapsed_seconds": 780.0,
		"events": [
			{"event": "retry", "payload": {}},
			{"event": "retry", "payload": {}},
			{"event": "damage_received", "payload": {"amount": 25.0}},
			{"event": "invalid_target_attempt", "payload": {}},
			{"event": "invalid_target_attempt", "payload": {}},
			{"event": "invalid_target_attempt", "payload": {}},
			{"event": "route_taken", "payload": {"route_tags": ["contractor_access"]}},
			{"event": "level_completed", "payload": {}},
		]
	})

	assert_bool(bool(summary["completed"])).is_true()
	assert_int(int(summary["retries"])).is_equal(2)
	assert_float(float(summary["damage_received"])).is_equal(25.0)
	assert_int((summary["recommendations"] as Array).size()).is_equal(2)
	assert_array(summary["routes"] as Array).contains(["contractor_access"])


func test_hardening_variant_is_data_only_and_valid() -> void:
	var registry := ContentRegistry.new()
	assert_bool(registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)).is_true()
	var load_result := LevelSpecLoader.load_file(VARIANT_PATH)
	assert_bool(load_result.is_success()).is_true()
	var validation := LevelValidator.validate(load_result.spec, registry)

	assert_bool(validation.is_valid()).is_true()
	assert_str(load_result.spec.level_id()).is_equal("mvp_hardening_variant")
