extends SceneTree

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const LEVEL_DIRECTORY := "res://data/levels"
const PROFILE_DIRECTORY := "res://data/level_profiles"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level_paths := _discover_level_specs()
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var errors := ContentBatchValidator.validate(catalog, CATALOG_PATH, level_paths)
	var level_ids := PackedStringArray()
	for level_path: String in level_paths:
		var load_result := LevelSpecLoader.load_file(level_path)
		if load_result.is_success():
			level_ids.append(String(load_result.spec.level_id()))
	var profile_count := 0
	if DirAccess.dir_exists_absolute(PROFILE_DIRECTORY):
		for file_name: String in DirAccess.get_files_at(PROFILE_DIRECTORY):
			if not file_name.ends_with(".json"):
				continue
			profile_count += 1
			var profile_path := PROFILE_DIRECTORY.path_join(file_name)
			var profile_result := LevelPlaytestProfile.load_and_validate(profile_path, level_ids)
			for profile_error: String in profile_result["errors"] as PackedStringArray:
				errors.append(profile_error)
	if not errors.is_empty():
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	print("CONTENT VALIDATION PASS: catalog + %d LevelSpecs + %d playtest profiles" % [level_paths.size(), profile_count])
	quit(0)


func _discover_level_specs() -> PackedStringArray:
	var paths := PackedStringArray()
	for file_name: String in DirAccess.get_files_at(LEVEL_DIRECTORY):
		if file_name.ends_with(".json") and not file_name.ends_with(".schema.json"):
			paths.append(LEVEL_DIRECTORY.path_join(file_name))
	paths.sort()
	return paths
