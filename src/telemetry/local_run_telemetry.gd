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

var level_id: StringName = &""
var class_id: StringName = &""
var lens_id: StringName = &""
var events: Array[Dictionary] = []
var _elapsed: float = 0.0


func _process(delta: float) -> void:
	_elapsed += delta


func configure(run_level_id: StringName, run_class_id: StringName, run_lens_id: StringName = &"") -> void:
	level_id = run_level_id
	class_id = run_class_id
	lens_id = run_lens_id
	events.clear()
	_elapsed = 0.0
	record_event(&"level_loaded")


func record_event(event_type: StringName, payload: Dictionary = {}) -> bool:
	if event_type not in SUPPORTED_EVENTS:
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
		"schema_version": 0,
		"level_id": String(level_id),
		"class_id": String(class_id),
		"lens_id": String(lens_id),
		"elapsed_seconds": snappedf(_elapsed, 0.001),
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
