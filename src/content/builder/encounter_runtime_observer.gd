class_name EncounterRuntimeObserver
extends Node

signal resolved(encounter_id: StringName, resolution: StringName)

var encounter_id: StringName = &""
var allowed_resolutions: Array[StringName] = []
var neutralization_resolution: StringName = &""
var rule_interaction_resolution: StringName = &""
var _actors: Array[CombatTarget] = []
var _neutralized_actor_ids: Dictionary = {}
var _resolved: bool = false
var _resolution: StringName = &""


func configure(
	id: StringName,
	definition: EncounterDefinition,
	actors: Array[CombatTarget],
	rule_objects: Array[RuleStateObject]
) -> void:
	encounter_id = id
	allowed_resolutions = definition.allowed_resolutions.duplicate()
	neutralization_resolution = definition.neutralization_resolution
	rule_interaction_resolution = definition.rule_interaction_resolution
	_actors = actors.duplicate()
	for actor: CombatTarget in _actors:
		actor.neutralized.connect(_on_actor_neutralized.bind(actor.get_instance_id()))
	for rule_object: RuleStateObject in rule_objects:
		rule_object.state_changed.connect(_on_rule_state_changed)


func is_resolved() -> bool:
	return _resolved


func try_resolve(resolution: StringName) -> bool:
	if _resolved or resolution.is_empty() or resolution not in allowed_resolutions:
		return false
	_resolved = true
	_resolution = resolution
	resolved.emit(encounter_id, resolution)
	return true


func capture_runtime_state() -> Dictionary:
	return {
		"resolved": _resolved,
		"resolution": String(_resolution),
	}


func restore_runtime_state(snapshot: Dictionary) -> void:
	_resolved = bool(snapshot.get("resolved", false))
	_resolution = StringName(String(snapshot.get("resolution", "")))
	_neutralized_actor_ids.clear()


func _on_actor_neutralized(_target_id: StringName, instance_id: int) -> void:
	_neutralized_actor_ids[instance_id] = true
	if _neutralized_actor_ids.size() == _actors.size():
		try_resolve(neutralization_resolution)


func _on_rule_state_changed(
	_rule_id: StringName,
	_object_id: StringName,
	_previous_state: StringName,
	current_state: StringName,
	_interaction_tag: StringName
) -> void:
	if current_state != &"occupied" or _has_committed_aggressor():
		return
	if try_resolve(rule_interaction_resolution):
		for actor: CombatTarget in _actors:
			actor.stop_behavior()


func _has_committed_aggressor() -> bool:
	for actor: CombatTarget in _actors:
		if actor.conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR:
			return true
	return false
