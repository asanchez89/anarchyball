class_name ContentId
extends RefCounted

const VALID_PATTERN: String = "^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$"


static func is_valid(value: StringName) -> bool:
	if value.is_empty():
		return false
	var regex := RegEx.new()
	if regex.compile(VALID_PATTERN) != OK:
		return false
	return regex.search(String(value)) != null
