class_name WorldPropPlacement
extends RefCounted

const BALL_ORIGIN_TO_FLOOR: float = 24.0


static func scenery_support(platforms: Array, gates: Array, point: Vector2, width: float, depth: float) -> Vector2:
	var best := Vector2(INF, INF)
	var best_distance := INF
	for platform: Dictionary in platforms:
		var spans: Array[Vector2] = [Vector2(float(platform.x), float(platform.x) + float(platform.width))]
		for gate: Dictionary in gates:
			var remaining: Array[Vector2] = []
			var exclusion := Vector2(float(gate.x) - 90.0, float(gate.x) + 90.0)
			for span: Vector2 in spans:
				if exclusion.y <= span.x or exclusion.x >= span.y:
					remaining.append(span)
				else:
					if exclusion.x > span.x:
						remaining.append(Vector2(span.x, exclusion.x))
					if exclusion.y < span.y:
						remaining.append(Vector2(exclusion.y, span.y))
			spans = remaining
		for span: Vector2 in spans:
			if span.y - span.x < width:
				continue
			var candidate := Vector2(clampf(point.x, span.x + width * 0.5, span.y - width * 0.5), float(platform.y) + depth)
			var distance := candidate.distance_squared_to(point + Vector2(0, depth))
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best


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
