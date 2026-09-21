class_name ContractDefinition
extends ContentDefinition

@export var issuer_id: StringName = &""
@export var objective_id: StringName = &""
@export var reward_id: StringName = &""
@export var optional_cost_id: StringName = &""
@export var failure_condition_id: StringName = &""
@export var completion_flag_ids: Array[StringName] = []
@export var allowed_resolutions: Array[StringName] = []


func is_structurally_valid() -> bool:
	return (
		has_valid_identity()
		and ContentId.is_valid(issuer_id)
		and ContentId.is_valid(objective_id)
		and ContentId.is_valid(reward_id)
		and ContentId.is_valid(failure_condition_id)
		and not completion_flag_ids.is_empty()
		and not allowed_resolutions.is_empty()
	)
