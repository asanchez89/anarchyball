class_name ValidationIssue
extends RefCounted

var code: StringName
var field_path: String
var message: String


func _init(issue_code: StringName, path: String, detail: String) -> void:
	code = issue_code
	field_path = path
	message = detail


func format(source_path: String) -> String:
	return "%s: %s [%s]: %s" % [source_path, field_path, code, message]
