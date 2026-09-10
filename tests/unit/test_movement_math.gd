extends GdUnitTestSuite

var _profile: PlayerMovementProfile


func before_test() -> void:
	_profile = load("res://data/player/default_movement_profile.tres") as PlayerMovementProfile


func test_default_profile_is_valid() -> void:
	assert_object(_profile).is_not_null()
	assert_bool(_profile.is_valid()).is_true()
	assert_float(_profile.coyote_time).is_between(0.08, 0.15)
	assert_float(_profile.jump_buffer_time).is_between(0.08, 0.15)


func test_jump_metrics_derive_from_profile() -> void:
	assert_float(MovementMath.time_to_apex(_profile)).is_equal_approx(0.344444, 0.0001)
	assert_float(MovementMath.maximum_jump_height(_profile)).is_equal_approx(106.7777, 0.001)
	assert_float(MovementMath.conservative_horizontal_reach(_profile)).is_equal_approx(165.3333, 0.001)


func test_short_hop_only_cuts_upward_velocity() -> void:
	assert_float(MovementMath.short_hop_velocity(-600.0, 0.45)).is_equal(-270.0)
	assert_float(MovementMath.short_hop_velocity(200.0, 0.45)).is_equal(200.0)


func test_ground_acceleration_reaches_requested_speed_without_overshoot() -> void:
	var result := MovementMath.horizontal_velocity(290.0, 1.0, true, _profile, 1.0 / 60.0)
	assert_float(result).is_equal(300.0)
