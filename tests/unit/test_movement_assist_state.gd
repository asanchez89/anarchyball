extends GdUnitTestSuite


func test_coyote_jump_is_available_inside_window() -> void:
	var state := MovementAssistState.new()
	state.refresh_coyote(0.12)
	state.buffer_jump(0.12)
	state.tick(0.08)

	assert_bool(state.can_consume_jump(false)).is_true()


func test_coyote_jump_expires_outside_window() -> void:
	var state := MovementAssistState.new()
	state.refresh_coyote(0.12)
	state.buffer_jump(0.20)
	state.tick(0.13)

	assert_bool(state.can_consume_jump(false)).is_false()
	assert_bool(state.has_buffered_jump()).is_true()


func test_buffered_jump_survives_until_landing() -> void:
	var state := MovementAssistState.new()
	state.buffer_jump(0.12)
	state.tick(0.08)

	assert_bool(state.can_consume_jump(true)).is_true()
	state.consume_jump()
	assert_bool(state.can_consume_jump(true)).is_false()


func test_jump_buffer_expires() -> void:
	var state := MovementAssistState.new()
	state.buffer_jump(0.12)
	state.tick(0.13)

	assert_bool(state.has_buffered_jump()).is_false()
