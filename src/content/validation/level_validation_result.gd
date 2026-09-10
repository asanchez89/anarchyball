class_name LevelValidationResult
extends RefCounted

var source_path: String
var issues: Array[ValidationIssue] = []


func _init(path: String = "<memory>") -> void:
	source_path = path


func add_error(code: StringName, field_path: String, message: String) -> void:
	issues.append(ValidationIssue.new(code, field_path, message))


func is_valid() -> bool:
	return issues.is_empty()


func formatted_errors() -> PackedStringArray:
	var output := PackedStringArray()
	for issue: ValidationIssue in issues:
		output.append(issue.format(source_path))
	return output
