extends GdUnitTestSuite

const PROFILE_PATH := "res://data/level_profiles/occupancy_workshop_draft.json"


func test_workshop_is_explicitly_retained_as_non_shipping_prototype() -> void:
	var result := LevelPlaytestProfile.load_and_validate(
		PROFILE_PATH,
		PackedStringArray(["occupancy_workshop_draft"])
	)
	var profile := result["data"] as Dictionary

	assert_int((result["errors"] as PackedStringArray).size()).is_equal(0)
	assert_str(profile.get("lifecycle")).is_equal("technical_prototype")
	assert_str(profile.get("classification")).is_equal("technical_prototype")
	assert_str(profile.get("campaign_successor_id")).is_equal("w0_03_occupancy_workshop")
	assert_str((profile.get("decision") as Dictionary).get("action")).is_equal("retain_as_prototype")


func test_shipping_profile_requires_complete_production_ranges() -> void:
	var invalid_profile := {
		"schema_version": 0,
		"level_id": "shipping_fixture",
		"lifecycle": "generated_draft",
		"classification": "standard_mission",
		"beats": ["introduce", "demonstrate", "challenge", "combine", "climax"],
		"evidence_targets": {
			"minimum_first_clear_samples": 3,
			"minimum_clean_replay_samples": 3,
		},
		"targets": {"first_clear_seconds": [480, 720]},
	}
	var errors := LevelPlaytestProfile.validate(invalid_profile)

	assert_bool(errors.size() >= 4).is_true()
	assert_str("\n".join(errors)).contains("effective_route_screens")


func test_report_derives_section_checkpoint_route_and_evidence_gaps() -> void:
	var profile := (LevelPlaytestProfile.load_and_validate(PROFILE_PATH)["data"] as Dictionary)
	var report := TelemetryPlaytestReport.summarize([
		_completed_snapshot("first_clear", 420.0, 5.2),
		_completed_snapshot("clean_replay", 250.0, 4.9),
	], profile)

	assert_int(int(report["completed_runs"])).is_equal(2)
	assert_float(float(report["completion_rate"])).is_equal(1.0)
	assert_float(float((report["section_average_seconds"] as Dictionary)["section_teach"])).is_equal(90.0)
	assert_float(float((report["checkpoint_average_interval_seconds"] as Dictionary)["checkpoint_one"])).is_equal(180.0)
	assert_int(int((report["route_counts"] as Dictionary)["occupy_machine"])).is_equal(2)
	assert_int(int(report["total_retries"])).is_equal(2)
	assert_bool(bool(report["promotion_ready"])).is_false()
	assert_int((report["warnings"] as Array).size()).is_equal(3)


func test_section_time_does_not_complete_on_fall_or_backtrack() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"occupancy_workshop_draft", &"class_contractor")
	var trigger := auto_free(SectionTrigger.new()) as SectionTrigger
	trigger.section_id = &"section_fixture"
	trigger.completion_x = 1200.0
	trigger.telemetry = telemetry
	var player := auto_free(PlayerController.new()) as PlayerController
	player.global_position = Vector2(1100.0, 900.0)
	trigger._on_body_entered(player)
	trigger._on_body_exited(player)
	assert_int(telemetry.events.size()).is_equal(2)

	player.global_position.x = 1200.0
	trigger._on_body_exited(player)
	assert_int(telemetry.events.size()).is_equal(3)
	assert_str((telemetry.events.back() as Dictionary).get("event")).is_equal("section_completed")


func _completed_snapshot(playtest_profile: String, duration: float, route_screens: float) -> Dictionary:
	return {
		"schema_version": 1,
		"level_id": "occupancy_workshop_draft",
		"playtest_profile": playtest_profile,
		"elapsed_seconds": duration,
		"effective_route_screens": route_screens,
		"backtracking_pixels": 128.0,
		"events": [
			{"event": "section_entered", "time_seconds": 0.0, "payload": {"section_id": "section_teach"}},
			{"event": "section_completed", "time_seconds": 90.0, "payload": {"section_id": "section_teach"}},
			{"event": "checkpoint_used", "time_seconds": 180.0, "payload": {"checkpoint_id": "checkpoint_one"}},
			{"event": "route_taken", "time_seconds": 200.0, "payload": {"route_tags": ["occupy_machine"]}},
			{"event": "retry", "time_seconds": 240.0, "payload": {"checkpoint_id": "checkpoint_one"}},
			{"event": "level_completed", "time_seconds": duration, "payload": {}},
		],
	}
