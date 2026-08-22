extends PanelContainer

@onready var _movement_value: Label = %MovementValue
@onready var _directional_aim_value: Label = %DirectionalAimValue
@onready var _pointer_aim_value: Label = %PointerAimValue
@onready var _active_actions_value: Label = %ActiveActionsValue
@onready var _edge_events_value: Label = %EdgeEventsValue

var _last_edge_event := "none"


func _process(_delta: float) -> void:
	_capture_edge_events()

	var viewport := get_viewport()
	var viewport_center := viewport.get_visible_rect().size * 0.5
	var pointer_aim := InputActions.pointer_aim_vector(
		viewport_center,
		viewport.get_mouse_position()
	)

	_movement_value.text = "%+.2f" % InputActions.movement_axis()
	_directional_aim_value.text = _format_vector(InputActions.directional_aim_vector())
	_pointer_aim_value.text = _format_vector(pointer_aim)

	var active := InputActions.active_actions()
	_active_actions_value.text = ", ".join(active) if not active.is_empty() else "none"
	_edge_events_value.text = _last_edge_event


func _capture_edge_events() -> void:
	for action: StringName in InputActions.REQUIRED_ACTIONS:
		if Input.is_action_just_pressed(action):
			_last_edge_event = "%s pressed" % action
		elif Input.is_action_just_released(action):
			_last_edge_event = "%s released" % action


func _format_vector(value: Vector2) -> String:
	return "(%+.2f, %+.2f)" % [value.x, value.y]
