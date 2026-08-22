class_name TestFoundation
extends GdUnitTestSuite


func test_bootstrap_scene_is_loadable() -> void:
	var bootstrap := load("res://src/core/bootstrap.tscn")
	assert_bool(bootstrap is PackedScene).is_true()


func test_required_input_actions_are_registered() -> void:
	for action: StringName in InputActions.REQUIRED_ACTIONS:
		assert_bool(InputMap.has_action(action)).is_true()
		assert_bool(InputMap.action_get_events(action).is_empty()).is_false()


func test_required_actions_have_desktop_and_gamepad_bindings() -> void:
	for action: StringName in InputActions.REQUIRED_ACTIONS:
		var has_desktop_binding := false
		var has_gamepad_binding := false

		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey or event is InputEventMouseButton:
				has_desktop_binding = true
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_gamepad_binding = true

		assert_bool(has_desktop_binding).is_true()
		assert_bool(has_gamepad_binding).is_true()


func test_all_bindings_accept_any_device() -> void:
	for action: StringName in InputActions.REQUIRED_ACTIONS:
		for event: InputEvent in InputMap.action_get_events(action):
			assert_int(event.device).is_equal(-1)


func test_input_helpers_are_deterministic() -> void:
	var pointer_aim := InputActions.pointer_aim_vector(Vector2.ZERO, Vector2.RIGHT)
	assert_bool(pointer_aim.is_equal_approx(Vector2.RIGHT)).is_true()


func test_compatibility_renderer_is_the_baseline() -> void:
	var renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	var mobile_renderer := str(
		ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")
	)
	assert_str(renderer).is_equal("gl_compatibility")
	assert_str(mobile_renderer).is_equal("gl_compatibility")
