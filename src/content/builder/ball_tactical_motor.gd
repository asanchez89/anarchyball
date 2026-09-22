class_name BallTacticalMotor
extends CharacterBody2D
## Physical traversal for an externally driven ball. Combat remains on its Area2D.

const FEET: float = 24.0
var actor: CombatTarget
var settings: CeasefireChallengeDefinition
var platforms: Array[DebugPlatform] = []
var airborne: bool = false
var cooldown: float = 0.0
var _landing_x: float = 0.0
var _drop_platform: DebugPlatform


func configure(target: CombatTarget, config: CeasefireChallengeDefinition, surfaces: Array[DebugPlatform]) -> void:
	actor = target
	settings = config
	platforms = surfaces
	collision_layer = 0
	collision_mask = 1
	top_level = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = FEET
	shape.shape = circle
	add_child(shape)


func _ready() -> void:
	global_position = actor.global_position


func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if _drop_platform != null and global_position.y - FEET > _drop_platform.global_position.y + _drop_platform.size.y * 0.5 + _drop_platform.collision_surface_depth:
		_clear_drop_exception()
	if not airborne:
		global_position = actor.global_position
		# Maintain real floor contact between commands, including platform velocity
		# on elevators. An Area2D visual alone cannot ride an AnimatableBody2D.
		velocity = Vector2(0.0, settings.jump_gravity * delta)
		move_and_slide()
		actor.global_position = global_position
		if not is_on_floor():
			airborne = true
			actor.tactical_airborne = true
			_landing_x = global_position.x
		return
	# Midpoint integration preserves arc height even for very fast relays.
	velocity.y += settings.jump_gravity * delta * 0.5
	if absf(global_position.x - _landing_x) < 3.0:
		velocity.x = 0.0
	elif absf(velocity.x * delta) > absf(_landing_x - global_position.x):
		velocity.x = (_landing_x - global_position.x) / delta
	move_and_slide()
	actor.global_position = global_position
	if is_on_floor():
		_clear_drop_exception()
		airborne = false
		actor.tactical_airborne = false
		velocity = Vector2.ZERO
		cooldown = settings.jump_cooldown
	else:
		velocity.y += settings.jump_gravity * delta * 0.5
	actor._update_ball_visual_state()


func _surfaces(bounds: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for platform: DebugPlatform in platforms:
		if not platform.is_rule_enabled():
			continue
		# Leave clearance for the forward floor/wall probes and safe landings.
		var left := maxf(bounds.x, platform.global_position.x - platform.size.x * 0.5 + FEET + 4.0)
		var right := minf(bounds.y, platform.global_position.x + platform.size.x * 0.5 - FEET - 4.0)
		if left <= right:
			result.append({"left": left, "right": right, "y": platform.global_position.y - platform.size.y * 0.5 + platform.collision_surface_depth - FEET, "platform": platform})
	return result


func _closest(point: Vector2, surfaces: Array[Dictionary]) -> int:
	var best := -1
	var distance := INF
	for i: int in surfaces.size():
		var surface := surfaces[i]
		var candidate := Vector2(clampf(point.x, surface.left, surface.right), surface.y)
		var score := candidate.distance_squared_to(point)
		if score < distance:
			distance = score
			best = i
	return best


func _edge(source: Dictionary, destination: Dictionary, goal_x: float) -> Dictionary:
	# Reject impossible surface pairs before testing alternative collision arcs.
	var discriminant: float = settings.jump_speed * settings.jump_speed + 2.0 * settings.jump_gravity * (destination.y - source.y)
	if discriminant <= 0.0:
		return {}
	var airtime: float = (settings.jump_speed + sqrt(discriminant)) / settings.jump_gravity
	var gap: float = maxf(0.0, maxf(destination.left - source.right, source.left - destination.right))
	if gap > settings.jump_horizontal_speed * airtime:
		return {}
	var direct := _preferred_edge(source, destination, goal_x)
	if not direct.is_empty():
		return direct
	# A raised solid step needs a run-up offset: launching at its wall or
	# directly underneath it cannot clear the side with a full-sized body.
	var launches: Array[float] = [clampf(goal_x, source.left, source.right)]
	for inset: float in [0.0, FEET * 2.0, FEET * 4.0, FEET * 6.0]:
		launches.append(clampf(source.left + inset, source.left, source.right))
		launches.append(clampf(source.right - inset, source.left, source.right))
	var landings: Array[float] = [clampf(goal_x, destination.left, destination.right), (destination.left + destination.right) * 0.5, destination.left, destination.right]
	for launch: float in launches:
		for landing: float in landings:
			var arc := _ballistic_edge(source.y, destination.y, launch, landing)
			if not arc.is_empty():
				return arc
	return {}


func _preferred_edge(source: Dictionary, destination: Dictionary, goal_x: float) -> Dictionary:
	var overlap_left := maxf(source.left, destination.left)
	var overlap_right := minf(source.right, destination.right)
	var takeoff_x: float
	var landing_x: float
	if destination.y > source.y + 18.0 and overlap_left <= overlap_right:
		var support := source.get("platform") as DebugPlatform
		if support != null and support.size.y <= 32.0:
			var drop_x := clampf(goal_x, overlap_left, overlap_right)
			return {"takeoff": drop_x, "landing": drop_x, "vx": 0.0, "drop": support}
		# Descend around the edge, not vertically back onto the same one-way
		# deck. Clearance includes both halves of the body plus arc travel.
		var clearance := FEET * 3.5
		var can_left: bool = destination.left <= source.left - clearance
		var can_right: bool = destination.right >= source.right + clearance
		if not can_left and not can_right:
			return {}
		if can_left and (not can_right or goal_x < (source.left + source.right) * 0.5):
			takeoff_x = source.left
			landing_x = maxf(destination.left, source.left - clearance)
		else:
			takeoff_x = source.right
			landing_x = minf(destination.right, source.right + clearance)
	elif overlap_left <= overlap_right:
		takeoff_x = clampf(goal_x, overlap_left, overlap_right)
		landing_x = takeoff_x
	else:
		takeoff_x = source.right if source.right < destination.left else source.left
		landing_x = destination.left if source.right < destination.left else destination.right
	return _ballistic_edge(source.y, destination.y, takeoff_x, landing_x)


func _ballistic_edge(source_y: float, destination_y: float, takeoff_x: float, landing_x: float) -> Dictionary:
	var rise: float = destination_y - source_y
	var discriminant := settings.jump_speed * settings.jump_speed + 2.0 * settings.jump_gravity * rise
	if discriminant <= 0.0:
		return {}
	var duration := (settings.jump_speed + sqrt(discriminant)) / settings.jump_gravity
	var horizontal := (landing_x - takeoff_x) / duration
	if absf(horizontal) > settings.jump_horizontal_speed:
		return {}
	# Reject arcs crossing solid walls/closed gates. Thin one-way decks can be
	# crossed upwards; the body still lands on them through normal physics.
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = FEET - 2.0
	query.shape = circle
	query.collision_mask = 1
	for sample: int in range(1, 20):
		var time := duration * float(sample) / 20.0
		query.transform = Transform2D(0.0, Vector2(takeoff_x + horizontal * time, source_y - settings.jump_speed * time + 0.5 * settings.jump_gravity * time * time))
		for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
			var surface := hit.collider as DebugPlatform
			if surface == null or surface.size.y > 32.0:
				return {}
	return {"takeoff": takeoff_x, "landing": landing_x, "vx": horizontal}


func route_to(goal: Vector2, bounds: Vector2) -> Dictionary:
	var surfaces := _surfaces(bounds)
	var source := _closest(actor.global_position, surfaces)
	var destination := _closest(goal, surfaces)
	if source < 0 or destination < 0:
		return {}
	if source == destination:
		return {"walk": clampf(goal.x, surfaces[source].left, surfaces[source].right)}
	var queue: Array[int] = [source]
	var parents: Dictionary = {source: -1}
	var edges: Dictionary = {}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		for next: int in surfaces.size():
			if parents.has(next):
				continue
			# Jump from the nearest reachable takeoff instead of walking exposed
			# under the destination all the way to its final horizontal position.
			var edge := _edge(surfaces[current], surfaces[next], actor.global_position.x if current == source else goal.x)
			if edge.is_empty():
				continue
			parents[next] = current
			edges[next] = edge
			if next == destination:
				var first := next
				while int(parents[first]) != source:
					first = int(parents[first])
				return edges[first]
			queue.append(next)
	return {}


func travel(goal: Vector2, speed: float, bounds: Vector2, delta: float) -> void:
	if airborne:
		return
	global_position = actor.global_position
	var route := route_to(goal, bounds)
	if route.is_empty():
		actor.tactical_moving = false
		actor._set_patrolling(false)
		return
	var target_x := float(route.get("walk", route.get("takeoff", actor.global_position.x)))
	var next_x := move_toward(actor.global_position.x, target_x, speed * minf(delta, 0.1))
	var direction := signf(next_x - actor.global_position.x)
	if actor._ball_visual != null and not is_zero_approx(direction):
		actor._ball_visual.set_facing(direction)
	actor.tactical_moving = actor.try_grounded_step(next_x) and not is_zero_approx(direction)
	actor._set_patrolling(actor.tactical_moving)
	if not route.has("walk") and absf(actor.global_position.x - target_x) <= 2.0 and cooldown <= 0.0:
		global_position = actor.global_position
		if route.has("drop"):
			_drop_platform = route.drop
			add_collision_exception_with(_drop_platform)
			velocity = Vector2.ZERO
		else:
			velocity = Vector2(route.vx, -settings.jump_speed)
		_landing_x = route.landing
		airborne = true
		actor.tactical_airborne = true
		actor.tactical_moving = false
		actor._update_ball_visual_state()


func capture_runtime_state() -> Dictionary:
	return {"airborne": airborne, "velocity": velocity, "landing_x": _landing_x, "cooldown": cooldown, "drop_platform": String(_drop_platform.name) if _drop_platform != null else ""}


func _clear_drop_exception() -> void:
	if _drop_platform != null:
		remove_collision_exception_with(_drop_platform)
		_drop_platform = null


func restore_runtime_state(state: Dictionary) -> void:
	_clear_drop_exception()
	for platform: DebugPlatform in platforms:
		if String(platform.name) == String(state.get("drop_platform", "")):
			_drop_platform = platform
			add_collision_exception_with(platform)
			break
	airborne = bool(state.get("airborne", false))
	actor.tactical_airborne = airborne
	actor.tactical_moving = false
	velocity = state.get("velocity", Vector2.ZERO)
	_landing_x = float(state.get("landing_x", actor.global_position.x))
	cooldown = float(state.get("cooldown", 0.0))
	global_position = actor.global_position
