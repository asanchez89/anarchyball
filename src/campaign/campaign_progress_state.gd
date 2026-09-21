class_name CampaignProgressState
extends RefCounted

const SCHEMA_VERSION: int = 0

var world_id: StringName = &""
var active_mission_id: StringName = &""
var completed_mission_ids: Array[StringName] = []


func complete(mission_id: StringName, world: WorldDefinition) -> void:
	if mission_id not in completed_mission_ids:
		completed_mission_ids.append(mission_id)
	var index := -1
	for candidate_index: int in world.missions.size():
		if world.missions[candidate_index].mission_id == mission_id:
			index = candidate_index
			break
	active_mission_id = world.missions[index + 1].mission_id if index >= 0 and index + 1 < world.missions.size() else mission_id


func reconcile(world: WorldDefinition) -> void:
	if world == null or world.missions.is_empty():
		return
	var candidate := world.missions[0].mission_id
	for mission: CampaignMissionDefinition in world.missions:
		candidate = mission.mission_id
		if mission.mission_id not in completed_mission_ids:
			break
	active_mission_id = candidate


func to_dictionary() -> Dictionary:
	var completed: Array[String] = []
	for mission_id: StringName in completed_mission_ids:
		completed.append(String(mission_id))
	return {"schema_version": SCHEMA_VERSION, "world_id": String(world_id), "active_mission_id": String(active_mission_id), "completed_mission_ids": completed}


static func from_dictionary(data: Dictionary) -> CampaignProgressState:
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return null
	var state := CampaignProgressState.new()
	state.world_id = StringName(String(data.get("world_id", "")))
	state.active_mission_id = StringName(String(data.get("active_mission_id", "")))
	for value: Variant in data.get("completed_mission_ids", []) as Array:
		state.completed_mission_ids.append(StringName(String(value)))
	return state
