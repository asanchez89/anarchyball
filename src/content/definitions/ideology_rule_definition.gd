class_name IdeologyRuleDefinition
extends ContentDefinition

@export var hook_id: StringName = &""
@export var parameters: Dictionary = {}
@export var counterplay_tags: Array[StringName] = []


func is_structurally_valid() -> bool:
	return has_valid_identity() and not hook_id.is_empty() and not counterplay_tags.is_empty()
