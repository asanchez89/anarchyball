class_name IdeologyRuleDefinition
extends ContentDefinition

const HOOK_ACCESS_GATE: StringName = &"access_gate"
const HOOK_OCCUPANCY_MACHINE: StringName = &"occupancy_machine"
const SUPPORTED_HOOK_IDS: Array[StringName] = [HOOK_ACCESS_GATE, HOOK_OCCUPANCY_MACHINE]

@export var hook_id: StringName = &""
@export var parameters: Dictionary = {}
@export var counterplay_tags: Array[StringName] = []


func is_structurally_valid() -> bool:
	return has_valid_identity() and is_supported_hook(hook_id) and not counterplay_tags.is_empty()


static func is_supported_hook(candidate: StringName) -> bool:
	return candidate in SUPPORTED_HOOK_IDS
