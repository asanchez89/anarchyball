extends GdUnitTestSuite


func test_telemetry_records_required_local_balancing_signals() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"phase3_content_preview", &"class_contractor")
	telemetry.record_event(&"section_entered", {"section_id": "section_intro"})
	telemetry.record_event(&"retry", {"checkpoint_id": "checkpoint_start"})
	telemetry.record_event(&"damage_received", {"amount": 10.0, "position": {"x": 20.0, "y": 30.0}})
	telemetry.record_event(&"route_taken", {"route_tags": ["runner"]})
	telemetry.record_event(&"rule_state_changed", {"rule_id": "rule_occupancy_and_use", "object_id": "machine_safe_use", "from_state": "available", "to_state": "occupied", "interaction_tag": "occupy_machine"})
	telemetry.record_event(&"encounter_resolved", {"encounter_id": "encounter_preview", "resolution": "evade_and_extract"})

	var snapshot := telemetry.snapshot()
	assert_int(snapshot.get("schema_version")).is_equal(2)
	assert_str(snapshot.get("run_outcome")).is_equal("in_progress")
	assert_int((snapshot.get("events") as Array).size()).is_equal(7)


func test_invalid_target_attempt_records_decision_as_design_signal() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"phase3_content_preview", &"class_contractor")
	var permission := TargetPermission.block(TargetPermission.Decision.BLOCK_DISPUTED)
	telemetry.record_invalid_target(&"disputed_ball", permission)
	var event := telemetry.events.back() as Dictionary

	assert_str(event.get("event")).is_equal("invalid_target_attempt")
	assert_str((event.get("payload") as Dictionary).get("decision")).is_equal("BLOCK_DISPUTED")


func test_unknown_telemetry_event_is_rejected() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"phase3_content_preview", &"class_contractor")
	assert_bool(telemetry.record_event(&"arbitrary_network_event")).is_false()


func test_required_phase6_telemetry_payloads_are_enforced() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"occupancy_workshop_draft", &"class_contractor")

	assert_bool(telemetry.record_event(&"encounter_resolved", {"resolution": "neutralize_enforcer"})).is_false()
	assert_bool(telemetry.record_event(&"route_taken", {})).is_false()
	assert_bool(telemetry.record_event(&"rule_state_changed", {"rule_id": "rule_occupancy_and_use"})).is_false()
	assert_int(telemetry.events.size()).is_equal(1)


func test_playtest_profile_and_traversed_route_are_recorded() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"occupancy_workshop_draft", &"class_contractor", &"", &"first_clear")
	telemetry.track_player_position(Vector2(100.0, 600.0))
	telemetry.track_player_position(Vector2(1380.0, 600.0))
	telemetry.track_player_position(Vector2(1280.0, 600.0))
	var snapshot := telemetry.snapshot()

	assert_str(snapshot.get("playtest_profile")).is_equal("first_clear")
	assert_str(snapshot.get("run_id")).starts_with("occupancy_workshop_draft_")
	assert_float(float(snapshot.get("effective_route_screens"))).is_equal_approx(1.08, 0.01)
	assert_float(float(snapshot.get("backtracking_pixels"))).is_equal(100.0)
	assert_bool(telemetry.set_playtest_profile(&"invalid_profile")).is_false()
