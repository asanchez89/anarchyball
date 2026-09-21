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
	ABANDONED,
	DISPUTED,
}

const STATE_IDS: Array[StringName] = [
	&"inactive",
	&"available",
	&"occupied",
	&"disabled",
	&"abandoned",
	&"disputed",
]

var rule_id: StringName = &""
var object_id: StringName = &"rule_object"
var interaction_tag: StringName = &""
var machine_label: String = "OCCUPANCY MACHINE"
var current_state: State = State.INACTIVE
var targets_enabled_before_interaction: bool = false
var target_platforms: Array[DebugPlatform] = []
var _player_nearby: bool = false
var _label: Label
var _machine_sprite: Sprite2D


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
	_machine_sprite = Sprite2D.new()
	_machine_sprite.name = "MachineArt"
	_machine_sprite.texture = _texture_for_machine()
	_machine_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_machine_sprite.z_index = -1
	_machine_sprite.scale = Vector2.ONE * World0ArtMetrics.MACHINE_SCALE
	_machine_sprite.position = Vector2(
		0.0,
		-float(_machine_sprite.texture.get_height()) * World0ArtMetrics.MACHINE_SCALE * 0.5
	)
	add_child(_machine_sprite)
	_label = Label.new()
	_label.position = Vector2(-180.0, -156.0)
	_label.size = Vector2(360.0, 102.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	add_child(_label)
	_apply_state()


func _texture_for_machine() -> Texture2D:
	if "press" in String(object_id) or "mill" in String(object_id):
		return load("res://assets/art/props/world_0/machine_table.png") as Texture2D
	return load("res://assets/art/props/world_0/machine_console.png") as Texture2D


func _process(_delta: float) -> void:
	if _player_nearby and InputActions.is_interact_just_pressed():
		interact()


func configure_targets(platforms: Array[DebugPlatform]) -> void:
	target_platforms = platforms.duplicate()
	_apply_targets()


func interact() -> bool:
	if current_state != State.AVAILABLE and current_state != State.ABANDONED:
		return false
	return transition_to(State.OCCUPIED)


func transition_to(next_state: State, emit_event: bool = true) -> bool:
	if next_state < State.INACTIVE or next_state > State.DISPUTED or next_state == current_state:
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
	_update_machine_art()
	queue_redraw()


func _update_machine_art() -> void:
	if _machine_sprite == null:
		return
	var colors: Array[Color] = [
		Color("8991a3"), Color("ffd277"), Color("9dffc5"),
		Color("d17a82"), Color("c3ad82"), Color("c8a9ff"),
	]
	_machine_sprite.modulate = colors[current_state]


func _apply_targets() -> void:
	var enabled := (
		current_state == State.OCCUPIED
		or current_state == State.DISPUTED
		or (targets_enabled_before_interaction and current_state in [State.AVAILABLE, State.ABANDONED])
	)
	for platform: DebugPlatform in target_platforms:
		if is_instance_valid(platform):
			platform.set_rule_enabled(enabled)


func _update_label() -> void:
	if _label == null:
		return
	_label.text = "%s · %s\n%s  %s\n%s" % [
		machine_label,
		String(object_id).to_upper(),
		_state_symbol(),
		String(state_id()).to_upper(),
		guidance_text(),
	]


func guidance_text() -> String:
	match current_state:
		State.AVAILABLE:
			return "F / X: OCCUPY + OPERATE" if _player_nearby else "APPROACH · THEN PRESS F / X"
		State.ABANDONED:
			return "F / X: RESTORE + OPERATE" if _player_nearby else "CAN BE RESTORED · APPROACH"
		State.INACTIVE:
			return "NO CURRENT OPERATOR · CONTINUE"
		State.DISABLED:
			return "OUT OF SERVICE · USE OPEN ROUTE"
		State.DISPUTED:
			return "DO NOT ATTACK · FIND ◇ ALTERNATE MACHINE"
		_:
			return "NO ACTION HERE · CURRENT USE · CONTINUE RIGHT"


func _state_symbol() -> String:
	match current_state:
		State.AVAILABLE:
			return "[○]"
		State.OCCUPIED:
			return "[◆]"
		State.DISABLED:
			return "[×]"
		State.ABANDONED:
			return "[◇]"
		State.DISPUTED:
			return "[?]"
		_:
			return "[–]"


func _draw() -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		_player_nearby = true
		_update_label()


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		_player_nearby = false
		_update_label()
