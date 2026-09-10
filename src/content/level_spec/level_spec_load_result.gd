class_name LevelSpecLoadResult
extends RefCounted

var spec: LevelSpec
var errors: PackedStringArray = []


func is_success() -> bool:
	return spec != null and errors.is_empty()
