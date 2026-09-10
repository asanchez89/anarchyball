class_name LocalSaveStore
extends RefCounted

const DEFAULT_PATH := "user://saves/vertical_slice.json"


static func save(level_id: StringName, checkpoint: RunCheckpointState, path: String = DEFAULT_PATH) -> Error:
	if checkpoint == null:
		return ERR_INVALID_PARAMETER
	var directory := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		var directory_error := DirAccess.make_dir_recursive_absolute(directory)
		if directory_error != OK:
			return directory_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(checkpoint.to_dictionary(level_id), "  "))
	return OK


static func load_checkpoint(expected_level_id: StringName, path: String = DEFAULT_PATH) -> RunCheckpointState:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return null
	var data := parsed as Dictionary
	if StringName(String(data.get("level_id", ""))) != expected_level_id:
		return null
	return RunCheckpointState.from_dictionary(data)
