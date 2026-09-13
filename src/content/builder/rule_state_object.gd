class_name RuleStateObject
extends Area2D

signal state_changed(
	rule_id: StringName,
	object_id: StringName,
	previous_state: StringName,
	current_state: StringName,
	interaction_tag: StringName
)

enum State {
	INACTIVE,
	AVAILABLE,
	OCCUPIED,
	DISABLED,
}

const STATE_IDS: Array[StringName] = [
	&"inactive",
	&"available",
	&"occupied",
	&"disabled",
]

var rule_id: StringName = &""
var object_id: StringName = &"rule_object"
var interaction_tag: StringName = &""
var machine_label: String = "OCCUPANCY MACHINE"
var current_state: State = State.INACTIVE
var target_platforms: Array[DebugPlatform] = []
var _player_nearby: bool = false
var _label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(116.0, 126.0)
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_label = Label.new()
	_label.position = Vector2(-125.0, -118.0)
	_label.size = Vector2(250.0, 82.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	add_child(_label)
	_apply_state()


func _process(_delta: float) -> void:
	if _player_nearby and InputActions.is_interact_just_pressed():
		interact()


func configure_targets(platforms: Array[DebugPlatform]) -> void:
	target_platforms = platforms.duplicate()
	_apply_targets()


func interact() -> bool:
	if current_state != State.AVAILABLE:
		return false
	return transition_to(State.OCCUPIED)


func transition_to(next_state: State, emit_event: bool = true) -> bool:
	if next_state < State.INACTIVE or next_state > State.DISABLED or next_state == current_state:
		return false
	var previous := current_state
	current_state = next_state
	_apply_state()
	if emit_event:
		state_changed.emit(rule_id, object_id, state_id(previous), state_id(current_state), interaction_tag)
	return true


func capture_runtime_state() -> Dictionary:
	return {"state": String(state_id(current_state))}


func restore_runtime_state(data: Dictionary) -> bool:
	var restored_state := state_from_id(StringName(String(data.get("state", ""))))
	if restored_state < 0:
		return false
	if restored_state == current_state:
		_apply_state()
		return true
	return transition_to(restored_state, false)


func state_id(value: State = current_state) -> StringName:
	return STATE_IDS[value]


static func state_from_id(value: StringName) -> int:
	return STATE_IDS.find(value)


func _apply_state() -> void:
	_apply_targets()
	_update_label()
	queue_redraw()


func _apply_targets() -> void:
	var enabled := current_state == State.OCCUPIED
	for platform: DebugPlatform in target_platforms:
		if is_instance_valid(platform):
			platform.set_rule_enabled(enabled)


func _update_label() -> void:
	if _label == null:
		return
	var prompt := ""
	if current_state == State.AVAILABLE:
		prompt = "\nF / X: OCCUPY + OPERATE" if _player_nearby else "\nAPPROACH TO OPERATE"
	elif current_state == State.INACTIVE:
		prompt = "\nNO CURRENT OPERATOR"
	elif current_state == State.DISABLED:
		prompt = "\nOUT OF SERVICE"
	else:
		prompt = "\nPLATFORM ACTIVE"
	_label.text = "%s · %s\n%s  %s%s" % [machine_label, String(object_id).to_upper(), _state_symbol(), String(state_id()).to_upper(), prompt]


func _state_symbol() -> String:
	match current_state:
		State.AVAILABLE:
			return "[○]"
		State.OCCUPIED:
			return "[◆]"
		State.DISABLED:
			return "[×]"
		_:
			return "[–]"


func _draw() -> void:
	var colors: Array[Color] = [Color("70788a"), Color("f4b942"), Color("72d6a0"), Color("b2555b")]
	var color := colors[current_state]
	draw_rect(Rect2(-46.0, -40.0, 92.0, 80.0), Color(color, 0.32), true)
	draw_rect(Rect2(-46.0, -40.0, 92.0, 80.0), color, false, 4.0)
	draw_circle(Vector2.ZERO, 22.0, color, false, 4.0)
	draw_line(Vector2(-30.0, 34.0), Vector2(30.0, 34.0), color, 5.0)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		_player_nearby = true
		_update_label()


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		_player_nearby = false
		_update_label()
