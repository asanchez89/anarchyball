class_name TelemetryPlaytestReport
extends RefCounted


static func summarize(snapshots: Array, profile: Dictionary) -> Dictionary:
	var level_id := String(profile.get("level_id", ""))
	var report := {
		"level_id": level_id,
		"lifecycle": String(profile.get("lifecycle", "")),
		"classification": String(profile.get("classification", "")),
		"decision": (profile.get("decision", {}) as Dictionary).duplicate(true),
		"total_runs": 0,
		"completed_runs": 0,
		"completion_rate": 0.0,
		"profile_counts": {},
		"average_duration_seconds": {},
		"average_effective_route_screens": {},
		"average_backtracking_screens": 0.0,
		"section_average_seconds": {},
		"checkpoint_average_interval_seconds": {},
		"route_counts": {},
		"total_retries": 0,
		"warnings": [],
		"promotion_ready": false,
	}
	var durations: Dictionary = {}
	var route_lengths: Dictionary = {}
	var section_durations: Dictionary = {}
	var checkpoint_intervals: Dictionary = {}
	var backtracking_values: Array[float] = []
	for snapshot_value: Variant in snapshots:
		if not snapshot_value is Dictionary:
			continue
		var snapshot := snapshot_value as Dictionary
		if String(snapshot.get("level_id", "")) != level_id:
			continue
		report["total_runs"] = int(report["total_runs"]) + 1
		if not _is_completed(snapshot):
			continue
		report["completed_runs"] = int(report["completed_runs"]) + 1
		var playtest_profile := String(snapshot.get("playtest_profile", "unspecified"))
		_increment(report["profile_counts"] as Dictionary, playtest_profile)
		_append_number(durations, playtest_profile, float(snapshot.get("elapsed_seconds", 0.0)))
		_append_number(route_lengths, playtest_profile, float(snapshot.get("effective_route_screens", 0.0)))
		backtracking_values.append(float(snapshot.get("backtracking_pixels", 0.0)) / LocalRunTelemetry.REFERENCE_VIEWPORT_WIDTH)
		_accumulate_events(snapshot.get("events", []) as Array, report, section_durations, checkpoint_intervals)
	if int(report["total_runs"]) > 0:
		report["completion_rate"] = snappedf(
			float(report["completed_runs"]) / float(report["total_runs"]),
			0.001
		)
	report["average_duration_seconds"] = _averages(durations)
	report["average_effective_route_screens"] = _averages(route_lengths)
	report["average_backtracking_screens"] = _average(backtracking_values)
	report["section_average_seconds"] = _averages(section_durations)
	report["checkpoint_average_interval_seconds"] = _averages(checkpoint_intervals)
	_apply_evidence_gate(report, profile)
	return report


static func load_run_directory(directory: String) -> Array:
	var snapshots: Array = []
	if not DirAccess.dir_exists_absolute(directory):
		return snapshots
	for file_name: String in DirAccess.get_files_at(directory):
		if not file_name.ends_with(".json"):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(directory.path_join(file_name))) == OK and parser.data is Dictionary:
			snapshots.append(parser.data as Dictionary)
	return snapshots


static func _is_completed(snapshot: Dictionary) -> bool:
	if snapshot.has("run_outcome"):
		return String(snapshot.get("run_outcome")) == "completed"
	for event_value: Variant in snapshot.get("events", []) as Array:
		if event_value is Dictionary and String((event_value as Dictionary).get("event", "")) == "level_completed":
			return true
	return false


static func _accumulate_events(
	events: Array,
	report: Dictionary,
	section_durations: Dictionary,
	checkpoint_intervals: Dictionary
) -> void:
	var section_starts: Dictionary = {}
	var previous_checkpoint_time: float = 0.0
	for event_value: Variant in events:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		var event_name := String(event.get("event", ""))
		var event_time := float(event.get("time_seconds", 0.0))
		var payload := event.get("payload", {}) as Dictionary
		match event_name:
			"section_entered":
				section_starts[String(payload.get("section_id", ""))] = event_time
			"section_completed":
				var section_id := String(payload.get("section_id", ""))
				if section_starts.has(section_id):
					_append_number(section_durations, section_id, event_time - float(section_starts[section_id]))
			"checkpoint_used":
				var checkpoint_id := String(payload.get("checkpoint_id", ""))
				_append_number(checkpoint_intervals, checkpoint_id, event_time - previous_checkpoint_time)
				previous_checkpoint_time = event_time
			"route_taken":
				for route_value: Variant in payload.get("route_tags", []) as Array:
					_increment(report["route_counts"] as Dictionary, String(route_value))
			"retry":
				report["total_retries"] = int(report["total_retries"]) + 1


static func _apply_evidence_gate(report: Dictionary, profile: Dictionary) -> void:
	var warnings := report["warnings"] as Array
	var evidence_targets := profile.get("evidence_targets", {}) as Dictionary
	var counts := report["profile_counts"] as Dictionary
	var first_required := int(evidence_targets.get("minimum_first_clear_samples", 3))
	var clean_required := int(evidence_targets.get("minimum_clean_replay_samples", 3))
	if int(counts.get("first_clear", 0)) < first_required:
		warnings.append("Faltan primeras vueltas: %d/%d." % [int(counts.get("first_clear", 0)), first_required])
	if int(counts.get("clean_replay", 0)) < clean_required:
		warnings.append("Faltan repeticiones limpias: %d/%d." % [int(counts.get("clean_replay", 0)), clean_required])
	if String(profile.get("lifecycle", "")) == "technical_prototype":
		warnings.append("El nivel es un prototipo técnico y no puede promoverse a shipping.")
		report["promotion_ready"] = false
	else:
		report["promotion_ready"] = warnings.is_empty()


static func _increment(values: Dictionary, key: String) -> void:
	values[key] = int(values.get(key, 0)) + 1


static func _append_number(values: Dictionary, key: String, value: float) -> void:
	if not values.has(key):
		values[key] = []
	(values[key] as Array).append(value)


static func _averages(values: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in values:
		var numbers: Array[float] = []
		numbers.assign(values[key] as Array)
		result[key] = _average(numbers)
	return result


static func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: float in values:
		total += value
	return snappedf(total / float(values.size()), 0.01)
