class_name ContractRuntimeObject
extends Node2D

signal state_changed(contract_id: StringName, previous_state: StringName, current_state: StringName)
signal resolved(contract_id: StringName, resolution: StringName)

enum State {
	OFFERED,
	ACTIVE,
	PERFORMED,
	BREACHED,
	RESOLVED,
}

const STATE_IDS: Array[StringName] = [
	&"offered",
	&"active",
	&"performed",
	&"breached",
	&"resolved",
]

var contract_id: StringName = &"contract"
var definition: ContractDefinition
var performance_x: float = 0.0
var resolution_position: Vector2 = Vector2.ZERO
var counterparty_escape_x: float = 0.0
var state: State = State.OFFERED
var player: PlayerController
var acceptance_gate: AccessGate
var resolution_gate: AccessGate
var encounter_observer: EncounterRuntimeObserver
var counterparty: CombatTarget
var reward: DebugPickup
var _offer_nearby: bool = false
var _resolution_nearby: bool = false
var _breach_remaining: float = -1.0
var _offer_label: Label
var _resolution_label: Label


func configure(
	id: StringName,
	contract_definition: ContractDefinition,
	tracked_player: PlayerController,
	entry_gate: AccessGate,
	final_gate: AccessGate,
	observer: EncounterRuntimeObserver,
	actor: CombatTarget,
	reward_pickup: DebugPickup,
	performance_trigger_x: float,
	resolution_world_position: Vector2,
	escape_x: float
) -> void:
	contract_id = id
	definition = contract_definition
	player = tracked_player
	acceptance_gate = entry_gate
	resolution_gate = final_gate
	encounter_observer = observer
	counterparty = actor
	reward = reward_pickup
	performance_x = performance_trigger_x
	resolution_position = resolution_world_position
	counterparty_escape_x = escape_x


func _ready() -> void:
	_build_offer_sensor()
	_build_resolution_sensor()
	_update_labels()
	if reward != null:
		reward.set_available(state == State.RESOLVED)
	queue_redraw()


func _process(delta: float) -> void:
	if state == State.OFFERED and _offer_nearby and InputActions.is_interact_just_pressed():
		accept_contract()
	elif state == State.BREACHED and _resolution_nearby and InputActions.is_interact_just_pressed():
		resolve_breach(definition.allowed_resolutions[0])
	if state == State.ACTIVE and player != null and player.global_position.x >= performance_x:
		mark_performed()
	if _breach_remaining >= 0.0:
		_breach_remaining -= delta
		if _breach_remaining <= 0.0:
			commit_breach()


func accept_contract() -> bool:
	if state != State.OFFERED:
		return false
	_transition_to(State.ACTIVE)
	if acceptance_gate != null:
		acceptance_gate.open_for_resolution()
	return true


func mark_performed() -> bool:
	if state != State.ACTIVE:
		return false
	_transition_to(State.PERFORMED)
	_breach_remaining = 1.0
	return true


func commit_breach() -> bool:
	if state != State.PERFORMED:
		return false
	_breach_remaining = -1.0
	_transition_to(State.BREACHED)
	if resolution_gate != null:
		resolution_gate.restore_open(false)
	if counterparty != null and counterparty_escape_x > counterparty.global_position.x:
		var tween := create_tween()
		tween.tween_property(counterparty, "global_position:x", counterparty_escape_x, 2.2)
	return true


func resolve_breach(resolution: StringName) -> bool:
	if state != State.BREACHED or definition == null or resolution not in definition.allowed_resolutions:
		return false
	_transition_to(State.RESOLVED)
	if resolution_gate != null:
		resolution_gate.open_for_resolution()
	if encounter_observer != null:
		encounter_observer.try_resolve(resolution)
	if reward != null:
		reward.set_available(true)
	resolved.emit(contract_id, resolution)
	return true


func capture_runtime_state() -> Dictionary:
	return {"state": String(state_id()), "breach_remaining": _breach_remaining}


func restore_runtime_state(snapshot: Dictionary) -> bool:
	var restored := STATE_IDS.find(StringName(String(snapshot.get("state", ""))))
	if restored < 0:
		return false
	state = restored
	_breach_remaining = float(snapshot.get("breach_remaining", -1.0))
	if acceptance_gate != null:
		acceptance_gate.restore_open(state != State.OFFERED)
	if resolution_gate != null:
		resolution_gate.restore_open(state == State.RESOLVED)
	if reward != null:
		reward.set_available(state == State.RESOLVED)
	_update_labels()
	queue_redraw()
	return true


func state_id() -> StringName:
	return STATE_IDS[state]


func _transition_to(next_state: State) -> void:
	var previous := state_id()
	state = next_state
	_update_labels()
	queue_redraw()
	state_changed.emit(contract_id, previous, state_id())


func _build_offer_sensor() -> void:
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(150.0, 150.0)
	collision.shape = shape
	sensor.add_child(collision)
	sensor.body_entered.connect(func(body: Node2D) -> void:
		if body is PlayerController:
			_offer_nearby = true
			_update_labels()
	)
	sensor.body_exited.connect(func(body: Node2D) -> void:
		if body is PlayerController:
			_offer_nearby = false
			_update_labels()
	)
	add_child(sensor)
	_offer_label = _make_label(Vector2(-170.0, -145.0))
	add_child(_offer_label)


func _build_resolution_sensor() -> void:
	var sensor := Area2D.new()
	sensor.position = to_local(resolution_position)
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(170.0, 150.0)
	collision.shape = shape
	sensor.add_child(collision)
	sensor.body_entered.connect(func(body: Node2D) -> void:
		if body is PlayerController:
			_resolution_nearby = true
			_update_labels()
	)
	sensor.body_exited.connect(func(body: Node2D) -> void:
		if body is PlayerController:
			_resolution_nearby = false
			_update_labels()
	)
	add_child(sensor)
	_resolution_label = _make_label(sensor.position + Vector2(-170.0, -145.0))
	add_child(_resolution_label)


func _make_label(at: Vector2) -> Label:
	var label := Label.new()
	label.position = at
	label.size = Vector2(340.0, 100.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	return label


func _update_labels() -> void:
	if _offer_label != null:
		var prompt := "\nF / X: ACCEPT" if state == State.OFFERED and _offer_nearby else ""
		_offer_label.text = "BRIDGE ACCESS CONTRACT · %s\nCOUNTERPARTY IS NOT A TARGET%s" % [String(state_id()).to_upper(), prompt]
	if _resolution_label != null:
		var resolution_prompt := "\nF / X: REROUTE GATE" if state == State.BREACHED and _resolution_nearby else ""
		_resolution_label.text = "COMPLIANCE CONTROL · %s\nRESOLVE HERE OR USE UPPER BYPASS%s" % [String(state_id()).to_upper(), resolution_prompt]


func _draw() -> void:
	var color := Color("72d6a0") if state == State.RESOLVED else Color("f4b942")
	draw_rect(Rect2(-44.0, -55.0, 88.0, 110.0), Color(color, 0.25), true)
	draw_rect(Rect2(-44.0, -55.0, 88.0, 110.0), color, false, 4.0)
	var local_resolution := to_local(resolution_position)
	draw_rect(Rect2(local_resolution - Vector2(44.0, 55.0), Vector2(88.0, 110.0)), Color(color, 0.25), true)
	draw_rect(Rect2(local_resolution - Vector2(44.0, 55.0), Vector2(88.0, 110.0)), color, false, 4.0)
