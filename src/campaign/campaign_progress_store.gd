class_name CampaignProgressStore
extends RefCounted

const DEFAULT_PATH := "user://saves/campaign_v0.json"


static func save(state: CampaignProgressState, path: String = DEFAULT_PATH) -> Error:
	if state == null:
		return ERR_INVALID_PARAMETER
	var directory := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		var error := DirAccess.make_dir_recursive_absolute(directory)
		if error != OK:
			return error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(state.to_dictionary(), "  "))
	return OK


static func load_state(path: String = DEFAULT_PATH) -> CampaignProgressState:
	if not FileAccess.file_exists(path):
		return null
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return CampaignProgressState.from_dictionary(value as Dictionary) if value is Dictionary else null
