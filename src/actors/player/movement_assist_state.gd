class_name MovementAssistState
extends RefCounted

var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0


func tick(delta: float) -> void:
	_coyote_remaining = maxf(_coyote_remaining - delta, 0.0)
	_jump_buffer_remaining = maxf(_jump_buffer_remaining - delta, 0.0)


func refresh_coyote(duration: float) -> void:
	_coyote_remaining = maxf(duration, 0.0)


func buffer_jump(duration: float) -> void:
	_jump_buffer_remaining = maxf(duration, 0.0)


func can_consume_jump(is_grounded: bool) -> bool:
	return has_buffered_jump() and (is_grounded or has_coyote_time())


func consume_jump() -> void:
	_jump_buffer_remaining = 0.0
	_coyote_remaining = 0.0


func reset() -> void:
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0


func has_coyote_time() -> bool:
	return _coyote_remaining > 0.0


func has_buffered_jump() -> bool:
	return _jump_buffer_remaining > 0.0


func coyote_remaining() -> float:
	return _coyote_remaining


func jump_buffer_remaining() -> float:
	return _jump_buffer_remaining
