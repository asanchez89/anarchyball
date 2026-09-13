class_name ClassLoadout
extends ContentDefinition

@export var weapon_id: StringName = &""
@export var ability_ids: Array[StringName] = []
@export var interaction_tags: Array[StringName] = []
@export var movement_speed_multiplier: float = 1.0


func is_structurally_valid() -> bool:
	return has_valid_identity() and not weapon_id.is_empty() and movement_speed_multiplier > 0.0
