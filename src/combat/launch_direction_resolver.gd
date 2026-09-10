class_name LaunchDirectionResolver
extends RefCounted

const MINIMUM_HORIZONTAL_COMPONENT: float = 0.15


static func resolve(requested_direction: Vector2, facing_direction: float) -> Vector2:
	var facing: float = -1.0 if facing_direction < 0.0 else 1.0
	if requested_direction.is_zero_approx():
		return Vector2(facing, 0.0)

	var resolved := requested_direction.normalized()
	resolved.x = absf(resolved.x) * facing
	if absf(resolved.x) < MINIMUM_HORIZONTAL_COMPONENT:
		resolved.x = MINIMUM_HORIZONTAL_COMPONENT * facing
	return resolved.normalized()
