class_name ConflictStateComponent
extends Node

signal state_changed(previous_state: State, new_state: State, reason: AggressorReason)

enum State {
	NEUTRAL,
	DISPUTED,
	THREATENING,
	AGGRESSOR,
	SURRENDERING,
	NEUTRALIZED,
}

enum AggressorReason {
	NONE,
	ATTACK_COMMITTED,
	FORCED_CONFISCATION,
	DETAIN_ORDER_EXECUTED,
	THIRD_PARTY_AGGRESSION,
	HOSTILE_MACHINE_ACTIVATED,
	ENCOUNTER_SCRIPT,
}

@export var initial_state: State = State.NEUTRAL

var current_state: State = State.NEUTRAL
var aggressor_reason: AggressorReason = AggressorReason.NONE
var protected_target_id: StringName = &""
var _previous_non_aggressor_state: State = State.NEUTRAL


func _ready() -> void:
	current_state = initial_state
	if current_state == State.THREATENING:
		_previous_non_aggressor_state = State.NEUTRAL


func begin_threatening() -> bool:
	if current_state not in [State.NEUTRAL, State.DISPUTED]:
		return false
	_previous_non_aggressor_state = current_state
	return _transition(State.THREATENING, AggressorReason.NONE)


func cancel_threat() -> bool:
	if current_state != State.THREATENING:
		return false
	return _transition(_previous_non_aggressor_state, AggressorReason.NONE)


func commit_aggression(reason: AggressorReason, defended_target_id: StringName = &"") -> bool:
	if reason == AggressorReason.NONE:
		return false
	if current_state in [State.SURRENDERING, State.NEUTRALIZED]:
		return false
	protected_target_id = defended_target_id
	return _transition(State.AGGRESSOR, reason)


func begin_surrender() -> bool:
	if current_state != State.AGGRESSOR:
		return false
	return _transition(State.SURRENDERING, aggressor_reason)


func neutralize() -> bool:
	if current_state not in [State.AGGRESSOR, State.SURRENDERING]:
		return false
	return _transition(State.NEUTRALIZED, aggressor_reason)


func reset_conflict(state: State = State.NEUTRAL) -> void:
	var previous := current_state
	current_state = state
	aggressor_reason = AggressorReason.NONE
	protected_target_id = &""
	_previous_non_aggressor_state = State.NEUTRAL if state == State.THREATENING else state
	state_changed.emit(previous, current_state, aggressor_reason)


func state_name() -> String:
	return State.keys()[current_state]


func reason_name() -> String:
	return AggressorReason.keys()[aggressor_reason]


func _transition(new_state: State, reason: AggressorReason) -> bool:
	if current_state == new_state and aggressor_reason == reason:
		return false
	var previous := current_state
	current_state = new_state
	aggressor_reason = reason
	state_changed.emit(previous, new_state, reason)
	return true
