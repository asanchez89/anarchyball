class_name LevelSpec
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 0

var source_path: String
var data: Dictionary


func _init(spec_data: Dictionary = {}, path: String = "<memory>") -> void:
	data = spec_data
	source_path = path


func level_id() -> StringName:
	return StringName(String(data.get("level_id", "")))
