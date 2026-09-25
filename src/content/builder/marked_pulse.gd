class_name MarkedPulse
extends Node2D
## A single announced ground attack. The parent owns the shared ceasefire clock.

var challenge: CeasefireChallenge
var pending: Dictionary = {}
var cooldown: float = 0.0
var bonus_used: float = 0.0
var sequence: int = 0
var burst_remaining: float = 0.0
var burst_point := Vector2.ZERO
var burst_radius: float = 0.0


func safe_mark(actor: CombatTarget) -> Dictionary:
	var motor := challenge._motors[actor.stable_id] as BallTacticalMotor
	var point := challenge.player.global_position
	for surface: Dictionary in motor._surfaces(challenge.zone):
		# Only target broad, currently enabled surfaces under the player. The
		# escape remains on that same floor, never across a gap or locked lift.
		if absf(point.y - float(surface.y)) > 40.0 or point.x < float(surface.left) or point.x > float(surface.right):
			continue
		var limits := Vector2(float(surface.left), float(surface.right))
		# Only advertise the walkable lane. Raised slabs and closed gates may
		# interrupt a broad underlying floor; test actual collision, not artwork.
		for side: int in 2:
			for height: float in [-BallTacticalMotor.FEET * 0.75, BallTacticalMotor.FEET * 0.75]:
				var origin := Vector2(point.x, float(surface.y) + height)
				var query := PhysicsRayQueryParameters2D.create(origin, Vector2(limits[side], origin.y), 1)
				var hit := get_world_2d().direct_space_state.intersect_ray(query)
				if not hit.is_empty():
					limits[side] = float((hit.position as Vector2).x) + (BallTacticalMotor.FEET if side == 0 else -BallTacticalMotor.FEET)
		var left := maxf(0.0, point.x - limits.x)
		var right := maxf(0.0, limits.y - point.x)
		var radius := minf(challenge.definition.pulse_radius, maxf(left, right) - 70.0)
		if radius < 24.0:
			continue
		var escape := radius + 70.0
		if maxf(left, right) < escape:
			continue
		# Conservative travel bound includes reaction time and acceleration.
		if escape > challenge.player.movement_profile.run_speed * maxf(0.0, challenge.definition.pulse_warning - 0.5):
			continue
		return {"x": point.x, "y": float(surface.y), "radius": radius, "left": limits.x, "right": limits.y, "platform": String((surface.platform as DebugPlatform).get_path()), "safe_lanes": safe_jump_lanes(actor, Vector2(point.x, float(surface.y)), surface.platform)}
	return {}


func safe_jump_lanes(actor: CombatTarget, origin: Vector2, source: DebugPlatform) -> Array[Dictionary]:
	var lanes: Array[Dictionary] = []
	var profile := challenge.player.movement_profile
	var width := challenge.definition.pulse_safe_lane_width
	var motor := challenge._motors[actor.stable_id] as BallTacticalMotor
	var best_distance := INF
	for surface: Dictionary in motor._surfaces(challenge.zone):
		var platform := surface.platform as DebugPlatform
		var rise := origin.y - float(surface.y)
		if platform == source or not is_zero_approx(platform.motion_distance_y()) or rise < 45.0 or rise > MovementMath.maximum_jump_height(profile) * 0.9 or float(surface.right) - float(surface.left) < width:
			continue
		var landing := Vector2(clampf(origin.x, float(surface.left) + width * 0.5, float(surface.right) - width * 0.5), float(surface.y))
		var discriminant := profile.jump_velocity * profile.jump_velocity - 2.0 * profile.gravity * rise
		var duration := (profile.jump_velocity + sqrt(discriminant)) / profile.gravity
		if duration + 0.5 > challenge.definition.pulse_warning or absf(landing.x - origin.x) > profile.run_speed * duration * 0.6:
			continue
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = (challenge.player.get_node("CollisionShape2D") as CollisionShape2D).shape
		query.collision_mask = 1
		var clear := true
		for sample: int in range(1, 32):
			var time := duration * float(sample) / 32.0
			var position := Vector2(lerpf(origin.x, landing.x, time / duration), origin.y - profile.jump_velocity * time + 0.5 * profile.gravity * time * time)
			query.transform = Transform2D(0.0, position)
			for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
				var obstacle := hit.collider as DebugPlatform
				if obstacle != null and obstacle.size.y <= 32.0 and time < profile.jump_velocity / profile.gravity:
					continue
				clear = false
				break
			if not clear:
				break
		var distance := origin.distance_squared_to(landing)
		if clear and distance < best_distance:
			best_distance = distance
			lanes = [{"left": landing.x - width * 0.5, "right": landing.x + width * 0.5, "y": landing.y, "platform": String(platform.get_path())}]
	return lanes


func advance(delta: float, sources: Array[CombatTarget] = []) -> void:
	var actors := challenge.observer._actors if sources.is_empty() else sources
	burst_remaining = maxf(0.0, burst_remaining - delta)
	cooldown = maxf(0.0, cooldown - delta)
	if not pending.is_empty():
		var actor := _source(StringName(pending.source))
		var floor_node := get_node_or_null(NodePath(String(pending.platform))) as DebugPlatform
		if actor == null or floor_node == null or not floor_node.is_rule_enabled() or actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
			pending.clear()
		else:
			pending.time = maxf(0.0, float(pending.time) - delta)
			if float(pending.time) <= 0.0:
				_detonate(actor)
		queue_redraw()
		return
	if cooldown > 0.0 or not challenge.player_in_zone():
		queue_redraw()
		return
	for offset: int in actors.size():
		var index := (sequence + offset) % actors.size()
		var actor := actors[index]
		if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			continue
		if actor.global_position.distance_to(challenge.player.global_position) > challenge.definition.activation_range:
			continue
		var mark := safe_mark(actor)
		if mark.is_empty():
			continue
		# Committing a visibly announced attack authorizes defensive response.
		if not challenge._commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED):
			continue
		pending = mark
		pending.source = String(actor.stable_id)
		pending.time = challenge.definition.pulse_warning
		pending.damage_events = challenge.damage_events
		if actor.sfx != null:
			actor.sfx.play_cue(&"pulse_warning")
		sequence = index + 1
		queue_redraw()
		return


func _source(id: StringName) -> CombatTarget:
	for actor: CombatTarget in challenge.observer._actors:
		if actor.stable_id == id:
			return actor
	return null


func _detonate(actor: CombatTarget) -> void:
	var mark := pending.duplicate()
	pending.clear()
	cooldown = challenge.definition.pulse_interval
	burst_remaining = challenge.definition.pulse_burst_seconds
	burst_radius = float(mark.get("radius", challenge.definition.pulse_radius))
	burst_point = Vector2(float(mark.x), float(mark.y) + BallTacticalMotor.FEET)
	var player := challenge.player
	var point := Vector2(float(mark.x), float(mark.y))
	var hit := absf(player.global_position.x - point.x) <= float(mark.get("radius", challenge.definition.pulse_radius)) + BallTacticalMotor.FEET and absf(player.global_position.y - point.y) < 45.0
	if hit:
		var epoch := challenge._restore_epoch
		var receiver := player.get_node("EffectReceiver") as EffectReceiverComponent
		var permission := receiver.receive_effect(actor.identity, EffectContext.encounter_effect(EffectContext.EffectType.KINETIC_DAMAGE), challenge.definition.pulse_damage)
		if epoch != challenge._restore_epoch:
			return
		if permission.allowed:
			# Push inward, and only with clearance for the full stopping distance.
			var center := (float(mark.left) + float(mark.right)) * 0.5
			var direction := signf(center - player.global_position.x)
			var distance := absf(center - player.global_position.x)
			var stopping := challenge.definition.pulse_push * challenge.definition.pulse_push / (2.0 * player.movement_profile.run_deceleration)
			if distance > stopping + BallTacticalMotor.FEET:
				player.velocity.x = direction * challenge.definition.pulse_push
	elif challenge.can_advance_ceasefire() and challenge.damage_events == int(mark.get("damage_events", challenge.damage_events)):
		var bonus := minf(challenge.definition.clean_dodge_bonus, maxf(0.0, challenge.definition.clean_dodge_cap - bonus_used))
		bonus_used += bonus
		challenge.remaining = maxf(0.0, challenge.remaining - bonus)


func capture() -> Dictionary:
	return {"pending": pending.duplicate(true), "cooldown": cooldown, "bonus_used": bonus_used, "sequence": sequence}


func restore(state: Dictionary) -> void:
	pending = (state.get("pending", {}) as Dictionary).duplicate(true)
	cooldown = maxf(0.0, float(state.get("cooldown", 0.0)))
	bonus_used = clampf(float(state.get("bonus_used", 0.0)), 0.0, challenge.definition.clean_dodge_cap)
	sequence = int(state.get("sequence", 0))
	burst_remaining = 0.0
	queue_redraw()


func _draw() -> void:
	if burst_remaining > 0.0 and not challenge.observer.is_resolved():
		var point := to_local(burst_point)
		var texture := challenge.definition.pulse_vfx
		if texture != null:
			texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var frames := challenge.definition.pulse_vfx_frames
			var frame_size := Vector2(texture.get_width() / float(frames), texture.get_height())
			var progress := 1.0 - burst_remaining / challenge.definition.pulse_burst_seconds
			var frame := clampi(int(progress * frames), 0, frames - 1)
			var rendered := frame_size * challenge.definition.pulse_vfx_scale
			var count := maxi(1, int(burst_radius * 2.0 / rendered.y))
			for index: int in count:
				var offset := (float(index) - float(count - 1) * 0.5) * rendered.y
				draw_set_transform((point + Vector2(offset, 0)).snapped(Vector2(2, 2)), -PI * 0.5)
				draw_texture_rect_region(texture, Rect2(Vector2(0, -rendered.y * 0.5), rendered), Rect2(Vector2(frame * frame_size.x, 0), frame_size))
			draw_set_transform(Vector2.ZERO)
	if pending.is_empty() or challenge.observer.is_resolved():
		return
	var center := to_local(Vector2(float(pending.x), float(pending.y) + BallTacticalMotor.FEET))
	var radius := float(pending.get("radius", challenge.definition.pulse_radius))
	var progress := 1.0 - float(pending.time) / challenge.definition.pulse_warning
	var tint := Color("ffcc45") if progress < 0.65 else Color("ff5566")
	# Mark the usable escape floor, inset by body clearance. These lanes are
	# derived from the same collision surface as the attack, never across gaps.
	var clearance := BallTacticalMotor.FEET + 8.0
	var safe_color := Color("35ffd1")
	for lane: Dictionary in pending.get("safe_lanes", []):
		var platform := get_node_or_null(NodePath(String(lane.platform))) as DebugPlatform
		if platform == null or not platform.is_rule_enabled():
			continue
		var start := to_local(Vector2(float(lane.left), float(lane.y) + BallTacticalMotor.FEET))
		var width := float(lane.right) - float(lane.left)
		draw_rect(Rect2(start - Vector2(0, 12), Vector2(width, 12)), Color(0.2, 1.0, 0.8, 0.3))
		for x: int in range(0, int(width) - 9, 18):
			draw_rect(Rect2(start + Vector2(x, -3), Vector2(9, 3)), safe_color)
			var lift := float(int(progress * 8.0) % 3) * 3.0
			draw_line(start + Vector2(x, -18 - lift), start + Vector2(x + 3, -21 - lift), safe_color, 3.0)
			draw_line(start + Vector2(x + 3, -21 - lift), start + Vector2(x + 6, -18 - lift), safe_color, 3.0)
	for span: Vector2 in [Vector2(float(pending.left) + clearance - float(pending.x), -radius - clearance), Vector2(radius + clearance, float(pending.right) - clearance - float(pending.x))]:
		if span.y - span.x < 24.0:
			continue
		var start := maxf(span.x, -300.0)
		var finish := minf(span.y, 300.0)
		if finish <= start:
			continue
		draw_rect(Rect2(center + Vector2(start, -12), Vector2(finish - start, 12)), Color(0.2, 1.0, 0.8, 0.22))
		for x: int in range(int(start), int(finish) - 6, 18):
			draw_rect(Rect2(center + Vector2(x, -3), Vector2(9, 3)), safe_color)
			# Moving chevrons provide a shape cue independent of red/green.
			var lift := float(int(progress * 8.0) % 3) * 3.0
			draw_line(center + Vector2(x, -18 - lift), center + Vector2(x + 3, -15 - lift), safe_color, 3.0)
			draw_line(center + Vector2(x + 3, -15 - lift), center + Vector2(x + 6, -18 - lift), safe_color, 3.0)
	for x: int in range(-int(radius), int(radius), 12):
		draw_rect(Rect2(center + Vector2(x, -6), Vector2(6, 6)), tint)
	draw_rect(Rect2(center + Vector2(-radius, -12), Vector2(radius * 2.0 * progress, 3)), tint)
