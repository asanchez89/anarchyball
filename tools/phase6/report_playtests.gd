extends SceneTree

const PROFILE_DIRECTORY := "res://data/level_profiles"
const DEFAULT_LEVEL_ID := "occupancy_workshop_draft"
const RUN_DIRECTORY := "user://telemetry/runs"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level_id := _argument_value("level-id", DEFAULT_LEVEL_ID)
	var profile_path := PROFILE_DIRECTORY.path_join("%s.json" % level_id)
	var profile_result := LevelPlaytestProfile.load_and_validate(profile_path)
	var errors := profile_result["errors"] as PackedStringArray
	if not errors.is_empty():
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	var snapshots := TelemetryPlaytestReport.load_run_directory(RUN_DIRECTORY)
	var report := TelemetryPlaytestReport.summarize(snapshots, profile_result["data"] as Dictionary)
	var output_path := "res://telemetry/%s_playtest_report.json" % level_id
	var output_directory := ProjectSettings.globalize_path(output_path.get_base_dir())
	var make_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if make_error != OK:
		push_error("No se pudo crear %s" % output_directory)
		quit(1)
		return
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo escribir %s" % output_path)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "  "))
	print("PLAYTEST REPORT PASS: %s -> %s" % [level_id, ProjectSettings.globalize_path(output_path)])
	print(JSON.stringify(report))
	quit(0)


func _argument_value(name: String, fallback: String) -> String:
	var prefix := "--%s=" % name
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback
