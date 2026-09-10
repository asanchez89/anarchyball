class_name MovementMath
extends RefCounted


static func horizontal_velocity(
	current_velocity: float,
	input_axis: float,
	is_grounded: bool,
	profile: PlayerMovementProfile,
	delta: float
) -> float:
	var clamped_axis: float = clampf(input_axis, -1.0, 1.0)
	var target_velocity: float = clamped_axis * profile.run_speed
	var acceleration: float
	if is_zero_approx(clamped_axis):
		acceleration = profile.run_deceleration if is_grounded else profile.air_acceleration
	else:
		acceleration = profile.run_acceleration if is_grounded else profile.air_acceleration * profile.air_control
	return move_toward(current_velocity, target_velocity, acceleration * delta)


static func vertical_velocity(
	current_velocity: float,
	profile: PlayerMovementProfile,
	delta: float
) -> float:
	return minf(current_velocity + profile.gravity * delta, profile.max_fall_speed)


static func short_hop_velocity(current_velocity: float, multiplier: float) -> float:
	if current_velocity >= 0.0:
		return current_velocity
	return current_velocity * clampf(multiplier, 0.0, 1.0)


static func time_to_apex(profile: PlayerMovementProfile) -> float:
	return profile.jump_velocity / profile.gravity


static func maximum_jump_height(profile: PlayerMovementProfile) -> float:
	return profile.jump_velocity * profile.jump_velocity / (2.0 * profile.gravity)


static func ideal_air_time(profile: PlayerMovementProfile) -> float:
	return 2.0 * time_to_apex(profile)


static func ideal_horizontal_reach(profile: PlayerMovementProfile) -> float:
	return profile.run_speed * ideal_air_time(profile)


static func conservative_horizontal_reach(profile: PlayerMovementProfile) -> float:
	return ideal_horizontal_reach(profile) * 0.8
