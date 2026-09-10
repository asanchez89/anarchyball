class_name VoluntaryDuelContext
extends Node

@export var duel_id: StringName = &""
@export var participant_ids: Array[StringName] = []
@export var active: bool = false


func permits(source_id: StringName, target_id: StringName, requested_duel_id: StringName) -> bool:
	return (
		active
		and not duel_id.is_empty()
		and requested_duel_id == duel_id
		and source_id in participant_ids
		and target_id in participant_ids
	)
