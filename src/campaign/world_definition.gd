class_name WorldDefinition
extends Resource

@export var world_id: StringName = &""
@export var display_name: String = ""
@export var missions: Array[CampaignMissionDefinition] = []


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not ContentId.is_valid(world_id):
		errors.append("world_id inválido")
	if display_name.is_empty():
		errors.append("display_name vacío")
	var seen: Dictionary = {}
	for mission: CampaignMissionDefinition in missions:
		if mission == null or not mission.is_structurally_valid():
			errors.append("misión inválida")
			continue
		if seen.has(mission.mission_id):
			errors.append("misión duplicada: %s" % mission.mission_id)
		seen[mission.mission_id] = true
	return errors


func mission_by_id(mission_id: StringName) -> CampaignMissionDefinition:
	for mission: CampaignMissionDefinition in missions:
		if mission.mission_id == mission_id:
			return mission
	return null
