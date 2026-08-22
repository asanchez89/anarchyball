extends SceneTree

const ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"jump",
	&"crouch_or_drop",
	&"attack_primary",
	&"attack_secondary",
	&"aim_left",
	&"aim_right",
	&"aim_up",
	&"aim_down",
	&"ability_1",
	&"ability_2",
	&"interact",
	&"dodge_or_dash",
	&"pause",
]


func _initialize() -> void:
	_configure_actions()
	_persist_actions()
	var save_error := ProjectSettings.save()
	if save_error != OK:
		push_error("Could not save project settings: %s" % error_string(save_error))
		quit(1)
		return

	print("Configured %d abstract input actions." % ACTIONS.size())
	quit(0)


func _configure_actions() -> void:
	for action: StringName in ACTIONS:
		_reset_action(action, 0.25)

	_add_key(&"move_left", KEY_A)
	_add_key(&"move_left", KEY_LEFT, false)
	_add_joy_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_button(&"move_left", JOY_BUTTON_DPAD_LEFT)

	_add_key(&"move_right", KEY_D)
	_add_key(&"move_right", KEY_RIGHT, false)
	_add_joy_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button(&"move_right", JOY_BUTTON_DPAD_RIGHT)

	_add_key(&"jump", KEY_SPACE, false)
	_add_joy_button(&"jump", JOY_BUTTON_A)

	_add_key(&"crouch_or_drop", KEY_S)
	_add_key(&"crouch_or_drop", KEY_DOWN, false)
	_add_joy_axis(&"crouch_or_drop", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button(&"crouch_or_drop", JOY_BUTTON_DPAD_DOWN)

	_add_mouse_button(&"attack_primary", MOUSE_BUTTON_LEFT)
	_add_joy_axis(&"attack_primary", JOY_AXIS_TRIGGER_RIGHT, 1.0)

	_add_mouse_button(&"attack_secondary", MOUSE_BUTTON_RIGHT)
	_add_joy_axis(&"attack_secondary", JOY_AXIS_TRIGGER_LEFT, 1.0)

	_add_key(&"aim_left", KEY_J)
	_add_joy_axis(&"aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_key(&"aim_right", KEY_L)
	_add_joy_axis(&"aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_key(&"aim_up", KEY_I)
	_add_joy_axis(&"aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_key(&"aim_down", KEY_K)
	_add_joy_axis(&"aim_down", JOY_AXIS_RIGHT_Y, 1.0)

	_add_key(&"ability_1", KEY_Q)
	_add_joy_button(&"ability_1", JOY_BUTTON_LEFT_SHOULDER)
	_add_key(&"ability_2", KEY_E)
	_add_joy_button(&"ability_2", JOY_BUTTON_RIGHT_SHOULDER)

	_add_key(&"interact", KEY_F)
	_add_joy_button(&"interact", JOY_BUTTON_X)

	_add_key(&"dodge_or_dash", KEY_SHIFT, false)
	_add_joy_button(&"dodge_or_dash", JOY_BUTTON_B)

	_add_key(&"pause", KEY_ESCAPE, false)
	_add_joy_button(&"pause", JOY_BUTTON_START)


func _persist_actions() -> void:
	for action: StringName in ACTIONS:
		ProjectSettings.set_setting(
			"input/%s" % action,
			{
				"deadzone": InputMap.action_get_deadzone(action),
				"events": InputMap.action_get_events(action),
			}
		)


func _reset_action(action: StringName, deadzone: float) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, deadzone)


func _add_key(action: StringName, keycode: Key, physical := true) -> void:
	var event := InputEventKey.new()
	event.device = -1
	if physical:
		event.physical_keycode = keycode
	else:
		event.keycode = keycode
	InputMap.action_add_event(action, event)


func _add_mouse_button(action: StringName, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.device = -1
	event.button_index = button
	InputMap.action_add_event(action, event)


func _add_joy_button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	InputMap.action_add_event(action, event)


func _add_joy_axis(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
