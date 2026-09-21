class_name WorldPropPlacement
extends RefCounted

const BALL_ORIGIN_TO_FLOOR: float = 24.0


static func grounded_position(
	platforms: Array,
	x: float,
	authored_y: float,
	collision_surface_depth: float,
	origin_to_floor: float = 0.0
) -> Vector2:
	return Vector2(x, grounded_y(platforms, x, authored_y, collision_surface_depth, origin_to_floor))


static func grounded_y(
	platforms: Array,
	x: float,
	authored_y: float,
	collision_surface_depth: float,
	origin_to_floor: float = 0.0
) -> float:
	var closest_surface := INF
	var closest_distance := INF
	for platform_value: Variant in platforms:
		var platform := platform_value as Dictionary
		var platform_x := float(platform.get("x", 0.0))
		var platform_width := float(platform.get("width", 0.0))
		if x < platform_x or x > platform_x + platform_width:
			continue
		var surface_y := float(platform.get("y", authored_y)) + collision_surface_depth
		var distance := absf(surface_y - authored_y)
		if distance < closest_distance:
			closest_surface = surface_y
			closest_distance = distance
	var surface_y := authored_y + collision_surface_depth if is_inf(closest_surface) else closest_surface
	return surface_y - origin_to_floor
