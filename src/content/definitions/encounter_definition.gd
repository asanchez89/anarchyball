class_name EncounterDefinition
extends ContentDefinition

@export var entry_condition: StringName = &"on_enter"
@export var objective: StringName = &""
@export var enemy_archetype_ids: Array[StringName] = []
@export var protected_archetype_id: StringName = &""
@export var is_boss: bool = false
@export var aggression_trigger_ids: Array[StringName] = []
@export var success_condition_ids: Array[StringName] = []
@export var failure_condition_ids: Array[StringName] = []
@export var surrender_condition_ids: Array[StringName] = []
@export var allowed_resolutions: Array[StringName] = []
@export var neutralization_resolution: StringName = &""
@export var rule_interaction_resolution: StringName = &""
@export var resource_collection_resolution: StringName = &""
@export var class_shortcut_tags: Array[StringName] = []
@export var lens_option_ids: Array[StringName] = []
@export var reward_ids: Array[StringName] = []
@export var telemetry_tags: Array[StringName] = []


func is_structurally_valid() -> bool:
	return (
		has_valid_identity()
		and not objective.is_empty()
		and not success_condition_ids.is_empty()
		and not allowed_resolutions.is_empty()
		and (neutralization_resolution.is_empty() or neutralization_resolution in allowed_resolutions)
		and (rule_interaction_resolution.is_empty() or rule_interaction_resolution in allowed_resolutions)
		and (resource_collection_resolution.is_empty() or resource_collection_resolution in allowed_resolutions)
		and (not is_boss or not aggression_trigger_ids.is_empty())
	)
