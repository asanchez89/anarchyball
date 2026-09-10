class_name AccessibilityStore
extends RefCounted

const DEFAULT_PATH: String = "user://settings/accessibility.json"


static func load_settings(path: String = DEFAULT_PATH) -> AccessibilitySettings:
	if not FileAccess.file_exists(path):
		return AccessibilitySettings.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return AccessibilitySettings.new()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return AccessibilitySettings.new()
	return AccessibilitySettings.from_dictionary(parsed as Dictionary)


static func save_settings(settings: AccessibilitySettings, path: String = DEFAULT_PATH) -> Error:
	if settings == null:
		return ERR_INVALID_PARAMETER
	var directory := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		var directory_error := DirAccess.make_dir_recursive_absolute(directory)
		if directory_error != OK:
			return directory_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(settings.to_dictionary(), "  "))
	return OK
