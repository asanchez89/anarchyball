class_name ContentDefinition
extends Resource

@export var content_id: StringName = &""
@export var display_name: String = ""
@export var tags: Array[StringName] = []


func has_valid_identity() -> bool:
	return not content_id.is_empty() and ContentId.is_valid(content_id)
