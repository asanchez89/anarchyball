class_name CampaignMissionDefinition
extends Resource

@export var mission_id: StringName = &""
@export var display_name: String = ""
@export var mission_scene: PackedScene


func is_structurally_valid() -> bool:
	return ContentId.is_valid(mission_id) and not display_name.is_empty() and mission_scene != null
