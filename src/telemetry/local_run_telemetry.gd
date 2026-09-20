class_name LocalRunTelemetry
extends Node

const SUPPORTED_EVENTS: Array[StringName] = [
	&"level_loaded",
	&"section_entered",
	&"section_completed",
	&"retry",
	&"checkpoint_used",
	&"damage_received",
	&"route_taken",
	&"rule_state_changed",
	&"encounter_resolved",
	&"invalid_target_attempt",
	&"defeat",
	&"softlock_error",
	&"level_completed",
]
const PLAYTEST_PROFILES: Array[StringName] = [
	&"unspecified",
	&"first_clear",
	&"clean_replay",
	&"completionist",
]
const REFERENCE_VIEWPORT_WIDTH: float = 1280.0

var level_id: StringName = &""
var class_id: StringName = &""
var lens_id: StringName = &""
var playtest_profile: StringName = &"unspecified"
var run_id: String = ""
var events: Array[Dictionary] = []
var _elapsed: float = 0.0
var _distance_travelled_pixels: float = 0.0
var _backtracking_pixels: float = 0.0
var _last_tracked_position: Vector2
var _has_tracked_position: bool = false
var _run_outcome: StringName = &"in_progress"
var _archived: bool = false


func _process(delta: float) -> void:
	_elapsed += delta


func configure(
	run_level_id: StringName,
	run_class_id: StringName,
	run_lens_id: StringName = &"",
	run_playtest_profile: StringName = &"unspecified"
) -> void:
	level_id = run_level_id
	class_id = run_class_id
	lens_id = run_lens_id
	playtest_profile = run_playtest_profile if run_playtest_profile in PLAYTEST_PROFILES else &"unspecified"
	run_id = "%s_%d_%d" % [String(level_id), int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	events.clear()
	_elapsed = 0.0
	_distance_travelled_pixels = 0.0
	_backtracking_pixels = 0.0
	_has_tracked_position = false
	_run_outcome = &"in_progress"
	_archived = false
	record_event(&"level_loaded")


func set_playtest_profile(value: StringName) -> bool:
	if value not in PLAYTEST_PROFILES:
		return false
	playtest_profile = value
	return true


func track_player_position(position: Vector2) -> void:
	if _has_tracked_position:
		var movement := position - _last_tracked_position
		_distance_travelled_pixels += movement.length()
		if movement.x < 0.0:
			_backtracking_pixels += absf(movement.x)
	_last_tracked_position = position
	_has_tracked_position = true


func reset_position_tracking(position: Vector2) -> void:
	_last_tracked_position = position
	_has_tracked_position = true


func record_event(event_type: StringName, payload: Dictionary = {}) -> bool:
	if event_type not in SUPPORTED_EVENTS or not _has_required_payload(event_type, payload):
		return false
	events.append({
		"event": String(event_type),
		"time_seconds": snappedf(_elapsed, 0.001),
		"level_id": String(level_id),
		"class_id": String(class_id),
		"lens_id": String(lens_id),
		"payload": payload.duplicate(true),
	})
	return true


func record_invalid_target(target_id: StringName, permission: TargetPermission) -> void:
	record_event(&"invalid_target_attempt", {
		"target_id": String(target_id),
		"decision": permission.decision_name(),
	})


func snapshot() -> Dictionary:
	return {
		"schema_version": 2,
		"run_id": run_id,
		"level_id": String(level_id),
		"class_id": String(class_id),
		"lens_id": String(lens_id),
		"playtest_profile": String(playtest_profile),
		"run_outcome": String(_run_outcome),
		"elapsed_seconds": snappedf(_elapsed, 0.001),
		"active_control_seconds": snappedf(_elapsed, 0.001),
		"distance_travelled_pixels": snappedf(_distance_travelled_pixels, 0.01),
		"effective_route_screens": snappedf(_distance_travelled_pixels / REFERENCE_VIEWPORT_WIDTH, 0.01),
		"backtracking_pixels": snappedf(_backtracking_pixels, 0.01),
		"events": events.duplicate(true),
	}


func save_local(path: String = "user://telemetry/latest_run.json") -> Error:
	var directory := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		var make_error := DirAccess.make_dir_recursive_absolute(directory)
		if make_error != OK:
			return make_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(), "  "))
	return OK


func save_completed_run(
	latest_path: String = "user://telemetry/latest_run.json",
	archive_directory: String = "user://telemetry/runs"
) -> Error:
	return save_run(&"completed", latest_path, archive_directory)


func save_run(
	outcome: StringName,
	latest_path: String = "user://telemetry/latest_run.json",
	archive_directory: String = "user://telemetry/runs"
) -> Error:
	if outcome not in [&"completed", &"restarted", &"abandoned"]:
		return ERR_INVALID_PARAMETER
	if _archived:
		return OK
	_run_outcome = outcome
	var latest_error := save_local(latest_path)
	if latest_error != OK:
		return latest_error
	if not DirAccess.dir_exists_absolute(archive_directory):
		var make_error := DirAccess.make_dir_recursive_absolute(archive_directory)
		if make_error != OK:
			return make_error
	var archive_error := save_local(archive_directory.path_join("%s.json" % run_id))
	if archive_error == OK:
		_archived = true
	return archive_error


func _has_required_payload(event_type: StringName, payload: Dictionary) -> bool:
	var required_fields := PackedStringArray()
	match event_type:
		&"route_taken":
			required_fields = PackedStringArray(["route_tags"])
		&"rule_state_changed":
			required_fields = PackedStringArray(["rule_id", "object_id", "from_state", "to_state", "interaction_tag"])
		&"encounter_resolved":
			required_fields = PackedStringArray(["encounter_id", "resolution"])
		&"invalid_target_attempt":
			required_fields = PackedStringArray(["target_id", "decision"])
	for field: String in required_fields:
		if not payload.has(field):
			return false
	return true
