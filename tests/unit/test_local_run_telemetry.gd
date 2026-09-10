extends GdUnitTestSuite


func test_telemetry_records_required_local_balancing_signals() -> void:
	var telemetry := auto_free(LocalRunTelemetry.new()) as LocalRunTelemetry
	telemetry.configure(&"phase3_content_preview", &"class_contractor")
	telemetry.record_event(&"section_entered", {"section_id": "section_intro"})
	telemetry.record_event(&"retry", {"checkpoint_id": "checkpoint_start"})
	telemetry.record_event(&"damage_received", {"amount": 10.0, "position": {"x": 20.0, "y": 30.0}})
	telemetry.record_event(&"route_taken", {"route_tags": ["runner"]})
	telemetry.record_event(&"encounter_resolved", {"resolution": "evade_and_extract"})

	var snapshot := telemetry.snapshot()
	assert_int(snapshot.get("schema_version")).is_equal(0)
	assert_int((snapshot.get("events") as Array).size()).is_equal(6)


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
