class_name CrewCoordination
extends Node2D

signal assignment_changed(crew_id: StringName, station: int, locally_coordinated: bool)

var definition: CrewCoordinationDefinition
var platforms: Array[DebugPlatform] = []
var disruptors: Array[CombatTarget] = []
var power_source: RuleStateObject
var local_assignments: Array[bool] = [false, false]
var _terminals: Array[Terminal] = []


class Terminal extends RuleStateObject:
	var coordinator: CrewCoordination
	var index: int

	func interaction_caption() -> String:
		return "SWITCH"

	func interaction_available() -> bool:
		return true

	func interact() -> bool:
		coordinator.assign_local(index, not coordinator.local_assignments[index])
		return true


func _ready() -> void:
	for index: int in definition.terminal_positions.size():
		var terminal := Terminal.new()
		terminal.name = "Team%d" % index
		terminal.position = definition.terminal_positions[index]
		terminal.coordinator = self
		terminal.index = index
		terminal.object_id = StringName(String(definition.content_id) + "_team_%d" % index)
		terminal.current_state = RuleStateObject.State.AVAILABLE
		terminal.action_hint = "F / X: alternar señal central y relevo local"
		add_child(terminal)
		terminal.target_platforms = [platforms[index]]
		_terminals.append(terminal)
	refresh()


func _process(_delta: float) -> void:
	refresh()


func assign_local(station: int, value: bool) -> void:
	if station < 0 or station >= local_assignments.size() or local_assignments[station] == value:
		return
	local_assignments[station] = value
	refresh()
	assignment_changed.emit(definition.content_id, station, value)


func central_signal_available() -> bool:
	for actor: CombatTarget in disruptors:
		if actor.conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR:
			return false
	return true


func channel_enabled(index: int) -> bool:
	return power_source.current_state == RuleStateObject.State.OCCUPIED and (local_assignments[index] or central_signal_available())


func refresh() -> void:
	for index: int in platforms.size():
		var enabled := channel_enabled(index)
		if platforms[index].is_rule_enabled() != enabled:
			platforms[index].set_rule_enabled(enabled)
		if index < _terminals.size():
			var terminal := _terminals[index]
			var mode := "RELEVO LOCAL" if local_assignments[index] else "SEÑAL CENTRAL"
			var status := "OPERANDO" if enabled else "SIN ALIMENTACIÓN" if power_source.current_state != RuleStateObject.State.OCCUPIED else "CENTRAL INTERRUMPIDA"
			terminal._label.text = "EQUIPO %s · %s\n%s\nF / X: cambiar coordinación" % ["A" if index == 0 else "B", mode, status]
			terminal._machine_sprite.modulate = Color("87eab8") if enabled else Color("e6ae72")


func capture_runtime_state() -> Dictionary:
	return {"local_assignments": local_assignments.duplicate()}


func restore_runtime_state(data: Dictionary) -> void:
	var values: Array = data.get("local_assignments", [false, false])
	for index: int in 2:
		local_assignments[index] = bool(values[index]) if index < values.size() else false
	refresh()
