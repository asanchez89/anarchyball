class_name RunCheckpointState
extends RefCounted

const SCHEMA_VERSION: int = 0

var checkpoint_id: StringName = &"level_start"
var player_position: Vector2 = Vector2.ZERO
var health: float = 100.0
var actor_states: Dictionary = {}
var collected_reward_ids: Array[StringName] = []
var world_rule_state: Dictionary = {}


func capture(
	id: StringName,
	position: Vector2,
	current_health: float,
	actors: Dictionary,
	reward_ids: Array[StringName],
	rule_state: Dictionary = {}
) -> void:
	checkpoint_id = id
	player_position = position
	health = current_health
	actor_states = actors.duplicate(true)
	collected_reward_ids = reward_ids.duplicate()
	world_rule_state = rule_state.duplicate(true)


func to_dictionary(level_id: StringName) -> Dictionary:
	var rewards: Array[String] = []
	for reward_id: StringName in collected_reward_ids:
		rewards.append(String(reward_id))
	return {
		"schema_version": SCHEMA_VERSION,
		"level_id": String(level_id),
		"checkpoint_id": String(checkpoint_id),
		"player_position": {"x": player_position.x, "y": player_position.y},
		"health": health,
		"actor_states": actor_states.duplicate(true),
		"collected_reward_ids": rewards,
		"world_rule_state": world_rule_state.duplicate(true),
	}


static func from_dictionary(data: Dictionary) -> RunCheckpointState:
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return null
	var position_value: Variant = data.get("player_position")
	if not position_value is Dictionary:
		return null
	var position := position_value as Dictionary
	var state := RunCheckpointState.new()
	state.checkpoint_id = StringName(String(data.get("checkpoint_id", "level_start")))
	state.player_position = Vector2(float(position.get("x", 0.0)), float(position.get("y", 0.0)))
	state.health = maxf(float(data.get("health", 1.0)), 1.0)
	state.actor_states = (data.get("actor_states", {}) as Dictionary).duplicate(true)
	for reward_value: Variant in data.get("collected_reward_ids", []) as Array:
		state.collected_reward_ids.append(StringName(String(reward_value)))
	state.world_rule_state = (data.get("world_rule_state", {}) as Dictionary).duplicate(true)
	return state
