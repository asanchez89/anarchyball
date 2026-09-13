extends SceneTree

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const LEVEL_DIRECTORY := "res://data/levels"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level_paths := _discover_level_specs()
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var errors := ContentBatchValidator.validate(catalog, CATALOG_PATH, level_paths)
	if not errors.is_empty():
		for error: String in errors:
			push_error(error)
		quit(1)
		return
	print("CONTENT VALIDATION PASS: catalog + %d LevelSpecs" % level_paths.size())
	quit(0)


func _discover_level_specs() -> PackedStringArray:
	var paths := PackedStringArray()
	for file_name: String in DirAccess.get_files_at(LEVEL_DIRECTORY):
		if file_name.ends_with(".json") and not file_name.ends_with(".schema.json"):
			paths.append(LEVEL_DIRECTORY.path_join(file_name))
	paths.sort()
	return paths
