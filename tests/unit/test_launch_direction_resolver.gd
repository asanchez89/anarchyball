extends GdUnitTestSuite


func test_launch_follows_right_facing_side_when_pointer_is_behind() -> void:
	var result := LaunchDirectionResolver.resolve(Vector2(-1.0, -0.4), 1.0)
	assert_float(result.x).is_greater(0.0)
	assert_float(result.y).is_less(0.0)


func test_launch_follows_left_facing_side_when_pointer_is_behind() -> void:
	var result := LaunchDirectionResolver.resolve(Vector2(1.0, 0.25), -1.0)
	assert_float(result.x).is_less(0.0)
	assert_float(result.y).is_greater(0.0)


func test_vertical_aim_keeps_a_horizontal_facing_component() -> void:
	var result := LaunchDirectionResolver.resolve(Vector2.UP, -1.0)
	assert_float(result.x).is_less(0.0)
	assert_float(result.length()).is_equal_approx(1.0, 0.0001)


func test_empty_aim_uses_facing_direction() -> void:
	assert_vector(LaunchDirectionResolver.resolve(Vector2.ZERO, -1.0)).is_equal(Vector2.LEFT)
