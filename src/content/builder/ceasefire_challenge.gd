class_name CeasefireChallenge
extends Node

var definition: CeasefireChallengeDefinition
var observer: EncounterRuntimeObserver
var player: PlayerController
var zone := Vector2.ZERO
var remaining: float
var started: bool = false
var dealt_damage: bool = false
var received_damage: bool = false
var damage_events: int = 0
var stolen: Dictionary = {}
var stolen_by_actor: Dictionary = {}
var restoring: bool = false
var _warning: float = 0.0
var _turn_clock: float = 0.0
var _turn: int = 0
var _contacts: Dictionary = {}
var _health_before: float = 100.0
var _restore_epoch: int = 0
var _panel: PanelContainer
var _label: Label
var _bar: ProgressBar
var _homes: Dictionary = {}
var _motors: Dictionary = {}
var _roles: Dictionary = {}
var _cover_cooldown: float = 0.0
var _goals: Dictionary = {}
var _relieved: Dictionary = {}
var _returning: Dictionary = {}
var _raid_warnings: Dictionary = {}
var _surrender_awards: Dictionary = {}
var _surrender_bonus_used: float = 0.0
var _encirclements: Dictionary = {}
var pulse: MarkedPulse
var _stage_elapsed: float = 0.0
var _contact_windows: Dictionary = {}
var _mixed_budget: bool = false
var _group_turns: Dictionary = {}


func configure(owner_observer: EncounterRuntimeObserver, settings: CeasefireChallengeDefinition, actor_player: PlayerController) -> void:
	observer = owner_observer
	definition = settings
	player = actor_player
	remaining = definition.duration
	zone = Vector2(INF, -INF)
	var surfaces: Array[DebugPlatform] = []
	for surface: Node in observer.get_parent().get_parent().get_node("Platforms").get_children():
		if surface is DebugPlatform:
			surfaces.append(surface)
	for actor: CombatTarget in observer._actors:
		actor.externally_managed = true
		actor.compact_status = definition.compact_actor_hud
		actor._update_presentation()
		zone.x = minf(zone.x, actor.global_position.x - definition.zone_padding)
		zone.y = maxf(zone.y, actor.global_position.x + definition.zone_padding)
		actor.receiver.effect_applied.connect(_on_defensive_effect)
		_homes[actor.stable_id] = actor.global_position
		var motor := BallTacticalMotor.new()
		motor.configure(actor, definition, surfaces)
		actor.add_child(motor)
		_motors[actor.stable_id] = motor
	_health_before = player.health.current_health
	player.health.health_changed.connect(_on_health_changed)
	pulse = MarkedPulse.new()
	pulse.challenge = self
	add_child(pulse)


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	_panel = PanelContainer.new()
	_panel.theme = preload("res://assets/ui/game_theme.tres")
	_panel.position = Vector2(660, 125)
	_panel.size = Vector2(585, 125)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_panel)
	var list := VBoxContainer.new()
	_panel.add_child(list)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = 520
	_label.add_theme_font_size_override("font_size", 12)
	list.add_child(_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size.y = 14
	_bar.show_percentage = false
	_bar.max_value = definition.duration
	list.add_child(_bar)
	_update_hud()


func player_in_zone() -> bool:
	return player.global_position.x >= zone.x and player.global_position.x <= zone.y and player.health.current_health > 0.0


func ceasefire_bounds() -> Vector2:
	if is_zero_approx(definition.ceasefire_core_fraction):
		return zone
	# Fixed authored footprint: retreats and patrols never drag the timer zone.
	var roster_left := zone.x + definition.zone_padding
	var roster_right := zone.y - definition.zone_padding
	var inset := maxf(0.0, roster_right - roster_left) * definition.ceasefire_core_fraction
	return Vector2(roster_left + inset, roster_right - inset)


func can_advance_ceasefire() -> bool:
	var bounds := ceasefire_bounds()
	return player_in_zone() and player.global_position.x >= bounds.x and player.global_position.x <= bounds.y


func _physics_process(delta: float) -> void:
	advance(delta)
	_update_hud()


func advance(delta: float) -> void:
	if restoring or observer.is_resolved():
		return
	for actor: CombatTarget in observer._actors:
		actor.tactical_moving = false
		actor.external_patrol_enabled = not _roles.has(actor.stable_id) and not _returning.has(actor.stable_id)
	var surrendered := 0
	for actor: CombatTarget in observer._actors:
		if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			surrendered += 1
	if started and (surrendered == observer._actors.size() or (definition.any_surrender_resolves and surrendered > 0)):
		finish(&"force_surrender")
		return
	if definition.mode == CeasefireChallengeDefinition.AttackMode.MIXED_STAGES:
		_advance_mixed(delta)
		return
	if definition.mode == CeasefireChallengeDefinition.AttackMode.CONTACT_RAID:
		_advance_raiders(delta)
		return
	if definition.mode == CeasefireChallengeDefinition.AttackMode.AUTONOMOUS_FLANK:
		_advance_flankers(delta)
		return
	if definition.mode == CeasefireChallengeDefinition.AttackMode.MARKED_PULSE:
		if player_in_zone():
			_warning += delta
			for actor: CombatTarget in observer._actors:
				actor.conflict_state.begin_threatening()
		else:
			_warning = 0.0
			for actor: CombatTarget in observer._actors:
				actor.conflict_state.cancel_threat()
		if _warning >= definition.warning_seconds or not pulse.pending.is_empty():
			pulse.advance(delta)
		if started and can_advance_ceasefire():
			remaining = maxf(0.0, remaining - delta)
			if is_zero_approx(remaining):
				finish(&"survive_ceasefire")
		return
	if definition.tactical_retreat and started:
		_advance_retreat(delta)
	if not player_in_zone():
		_warning = 0.0
		for actor: CombatTarget in observer._actors:
			actor.conflict_state.cancel_threat()
		return
	if started and can_advance_ceasefire():
		remaining = maxf(0.0, remaining - delta)
		if is_zero_approx(remaining):
			finish(&"survive_ceasefire")
			return
	_warning += delta
	for actor: CombatTarget in observer._actors:
		actor.conflict_state.begin_threatening()
	if _warning < definition.warning_seconds:
		return
	if definition.mode == CeasefireChallengeDefinition.AttackMode.ROTATING_FIRE:
		if definition.collective_commitment and observer._actors.any(func(member: CombatTarget) -> bool: return member.global_position.distance_to(player.global_position) <= definition.activation_range):
			for member: CombatTarget in observer._actors:
				if member.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR and _commit(member, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED):
					if member._ball_visual != null:
						member._ball_visual.set_facing(signf(player.global_position.x - member.global_position.x))
					member._begin_attack_visual()
		_turn_clock -= delta
		if _turn_clock <= 0.0:
			var actor := observer._actors[_turn % observer._actors.size()]
			_turn += 1
			_turn_clock = definition.turn_interval
			if not _is_relocating(actor) and actor.global_position.distance_to(player.global_position) <= definition.activation_range and _commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED):
				actor._launch_hostile_bolt()


func active_attack_count() -> int:
	var count := active_projectile_count()
	for window: float in _contact_windows.values():
		if window > 0.0:
			count += 1
	return count


func _advance_mixed(delta: float) -> void:
	var shared := definition
	_mixed_budget = true
	for id: Variant in _contact_windows.keys():
		_contact_windows[id] = maxf(0.0, float(_contact_windows[id]) - delta)
	if can_advance_ceasefire():
		_stage_elapsed += delta
	var offset := 0
	for group: int in shared.group_profiles.size():
		var members: Array[CombatTarget] = []
		for index: int in shared.group_sizes[group]:
			if offset + index < observer._actors.size():
				members.append(observer._actors[offset + index])
		offset += shared.group_sizes[group]
		if members.is_empty() or _stage_elapsed < shared.stage_delays[group]:
			continue
		definition = shared.group_profiles[group]
		var key := str(group)
		var turns: Dictionary = _group_turns.get(key, {})
		_turn = int(turns.get("turn", 0))
		_turn_clock = float(turns.get("clock", 0.0))
		for actor: CombatTarget in members:
			(_motors[actor.stable_id] as BallTacticalMotor).settings = definition
		if definition.any_surrender_resolves and members.any(func(actor: CombatTarget) -> bool: return actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]):
			for actor: CombatTarget in members:
				actor.stop_behavior()
				if actor.conflict_state.begin_surrender():
					actor._surrender_remaining = 0.8
				for projectile: Node in actor.get_parent().get_children():
					if projectile is HostileBolt and (projectile as HostileBolt).source_identity == actor.identity:
						projectile.queue_free()
		else:
			match definition.mode:
				CeasefireChallengeDefinition.AttackMode.ROTATING_FIRE:
					_advance_group_fire(members, delta)
				CeasefireChallengeDefinition.AttackMode.CONTACT_RAID:
					_advance_raiders(delta, members, false)
				CeasefireChallengeDefinition.AttackMode.AUTONOMOUS_FLANK:
					_advance_flankers(delta, members, false)
				CeasefireChallengeDefinition.AttackMode.MARKED_PULSE:
					pulse.advance(delta, members)
		_group_turns[key] = {"turn": _turn, "clock": _turn_clock}
	definition = shared
	_mixed_budget = false
	if started and can_advance_ceasefire():
		remaining = maxf(0.0, remaining - delta)
		if is_zero_approx(remaining):
			finish(&"survive_ceasefire")


func _advance_group_fire(members: Array[CombatTarget], delta: float) -> void:
	if started and definition.tactical_retreat:
		_advance_retreat(delta, members)
	if not player_in_zone():
		return
	var key := members[0].stable_id
	_raid_warnings[key] = float(_raid_warnings.get(key, 0.0)) + delta
	for actor: CombatTarget in members:
		actor.conflict_state.begin_threatening()
	if float(_raid_warnings[key]) < definition.warning_seconds:
		return
	if not members.any(func(actor: CombatTarget) -> bool: return actor.global_position.distance_to(player.global_position) <= definition.activation_range):
		return
	for actor: CombatTarget in members:
		_commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	_turn_clock = maxf(0.0, _turn_clock - delta)
	if _turn_clock > 0.0 or active_attack_count() >= 2:
		return
	var actor := members[_turn % members.size()]
	_turn += 1
	_turn_clock = definition.turn_interval
	if not _is_relocating(actor) and _commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED):
		actor._launch_hostile_bolt()


func active_projectile_count() -> int:
	var count := 0
	for actor: CombatTarget in observer._actors:
		for child: Node in actor.get_parent().get_children():
			if child is HostileBolt and not child.is_queued_for_deletion() and (child as HostileBolt).source_identity == actor.identity:
				count += 1
	return count


func _advance_flankers(delta: float, members: Array[CombatTarget] = [], tick_clock: bool = true) -> void:
	var actors := observer._actors if members.is_empty() else members
	_advance_encirclement(delta, actors)
	_turn_clock = maxf(0.0, _turn_clock - delta)
	var first := _turn
	for offset: int in actors.size():
		var index := (first + offset) % actors.size()
		var actor := actors[index]
		var id := actor.stable_id
		if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			if started and not _surrender_awards.has(id):
				var bonus := minf(definition.surrender_time_bonus, maxf(0.0, definition.surrender_bonus_cap - _surrender_bonus_used))
				_surrender_awards[id] = true
				_surrender_bonus_used += bonus
				remaining = maxf(0.0, remaining - bonus)
			continue
		var home: Vector2 = _homes[id]
		var bounds := Vector2(maxf(zone.x, home.x - definition.pursuit_radius), minf(zone.y, home.x + definition.pursuit_radius))
		var in_reach := player_in_zone() and player.global_position.x >= bounds.x and player.global_position.x <= bounds.y and actor.global_position.distance_to(player.global_position) <= definition.activation_range
		actor.external_patrol_enabled = false
		if not in_reach:
			_raid_warnings.erase(id)
			actor.conflict_state.cancel_threat()
			if actor.global_position.distance_to(home) > definition.home_tolerance or actor.tactical_airborne:
				(_motors[id] as BallTacticalMotor).travel(home, definition.return_speed, bounds, delta)
			else:
				actor.conflict_state.disengage_at_home()
				actor.external_patrol_enabled = true
			continue
		actor.conflict_state.begin_threatening()
		_raid_warnings[id] = float(_raid_warnings.get(id, 0.0)) + delta
		if float(_raid_warnings[id]) < definition.warning_seconds:
			continue
		var flank_offset := definition.flank_distance + float(index / 2) * definition.personal_space * 2.0
		var goal := player.global_position + Vector2(flank_offset * (-1.0 if index % 2 == 0 else 1.0), 0)
		goal.x = clampf(goal.x, bounds.x, bounds.y)
		var nearest_height := INF
		var motor := _motors[id] as BallTacticalMotor
		for surface: Dictionary in motor._surfaces(bounds):
			if goal.x < float(surface.left) or goal.x > float(surface.right):
				continue
			var point := PhysicsPointQueryParameters2D.new()
			point.position = Vector2(goal.x, float(surface.y))
			point.collision_mask = 1
			if not actor.get_world_2d().direct_space_state.intersect_point(point).is_empty():
				continue
			var height := absf(float(surface.y) - player.global_position.y)
			if height < nearest_height or (is_equal_approx(height, nearest_height) and float(surface.y) < goal.y):
				nearest_height = height
				goal.y = float(surface.y)
		var formation: Dictionary = _encirclements.get(actors[0].stable_id, {})
		if bool(formation.get("armed", false)):
			# Hold the established boundary so the player can actually cross it.
			# Once broken, the warning restarts before the next reposition.
			var anchors: Dictionary = formation.get("anchors", {})
			goal = anchors.get(id, Vector2(float(formation.left if index % 2 == 0 else formation.right), goal.y))
		goal.x = clampf(goal.x, bounds.x, bounds.y)
		(_motors[id] as BallTacticalMotor).travel(goal, definition.chase_speed, bounds, delta)
		if _turn_clock <= 0.0 and active_attack_count() < definition.simultaneous_attacks and _commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED):
			actor._launch_hostile_bolt()
			_turn_clock = definition.turn_interval
			_turn = index + 1
	if tick_clock and started and can_advance_ceasefire():
		remaining = maxf(0.0, remaining - delta)
		if is_zero_approx(remaining):
			finish(&"survive_ceasefire")


func _advance_encirclement(delta: float, actors: Array[CombatTarget]) -> void:
	if actors.is_empty():
		return
	# Independent subgroup state also works in mixed encounters.
	var key := actors[0].stable_id
	var state: Dictionary = _encirclements.get(key, {"hold": 0.0, "cooldown": 0.0, "bonus": 0.0, "armed": false, "notice": 0.0})
	_encirclements[key] = state
	state.cooldown = maxf(0.0, float(state.cooldown) - delta)
	state.notice = maxf(0.0, float(state.notice) - delta)
	var left := INF
	var right := -INF
	var active := 0
	var settled := true
	for actor: CombatTarget in actors:
		if actor.conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR and (actor.tactical_airborne or actor.tactical_moving):
			settled = false
		if actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR or absf(actor.global_position.y - player.global_position.y) > 120.0:
			continue
		left = minf(left, actor.global_position.x)
		right = maxf(right, actor.global_position.x)
		active += 1
	# The maneuver spans the encounter's full playable zone: the narrower
	# passive-timer core must not make physically escaping the pair impossible.
	if not started or not player_in_zone() or active < 2:
		state.armed = false
		state.hold = 0.0
		return
	if bool(state.armed):
		# Crossing both recorded and current bounds prevents passive awards
		# when enemies simply move past a stationary player.
		var crossed := player.global_position.x < minf(left, float(state.left)) - 24.0 or player.global_position.x > maxf(right, float(state.right)) + 24.0
		if crossed and absf(player.global_position.x - float(state.origin)) >= definition.flank_distance:
			var bonus := minf(definition.encirclement_bonus, maxf(0.0, definition.encirclement_bonus_cap - float(state.bonus)))
			state.bonus = float(state.bonus) + bonus
			remaining = maxf(0.0, remaining - bonus)
			state.armed = false
			state.hold = 0.0
			state.cooldown = definition.encirclement_cooldown
			state.notice = definition.warning_seconds
			for actor: CombatTarget in actors:
				_raid_warnings[actor.stable_id] = 0.0
				if actor.sfx != null:
					actor.sfx.play_cue(&"tactical_dash")
		return
	var bracketed := settled and left < player.global_position.x - 40.0 and right > player.global_position.x + 40.0 and right - left <= definition.flank_distance * 3.0
	state.hold = float(state.hold) + delta if bracketed and is_zero_approx(float(state.cooldown)) else 0.0
	if float(state.hold) >= definition.encirclement_hold:
		state.armed = true
		state.anchors = {}
		for actor: CombatTarget in actors:
			state.anchors[actor.stable_id] = actor.global_position
		state.left = left
		state.right = right
		state.origin = player.global_position.x


func _commit(actor: CombatTarget, reason: ConflictStateComponent.AggressorReason) -> bool:
	if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
		return false
	if actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
		if not actor.conflict_state.commit_aggression(reason):
			return false
		actor.aggression_committed.emit(actor.stable_id, reason)
	started = true
	return true


func _chase(actor: CombatTarget, delta: float) -> void:
	var direction := signf(player.global_position.x - actor.global_position.x)
	if actor._ball_visual != null:
		actor._ball_visual.set_facing(direction)
	if actor.global_position.distance_to(player.global_position) <= definition.contact_radius - 2.0:
		return
	var next_x := clampf(actor.global_position.x + direction * definition.chase_speed * delta, zone.x, zone.y)
	for other: CombatTarget in observer._actors:
		if other == actor or other.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			continue
		if absf(player.global_position.y - actor.global_position.y) < 40.0 and absf(other.global_position.y - actor.global_position.y) < 40.0 and absf(other.global_position.x - next_x) < definition.personal_space and absf(other.global_position.x - next_x) < absf(other.global_position.x - actor.global_position.x):
			return
	var home: Vector2 = _homes[actor.stable_id]
	var bounds := Vector2(maxf(zone.x, home.x - definition.pursuit_radius), minf(zone.y, home.x + definition.pursuit_radius))
	(_motors[actor.stable_id] as BallTacticalMotor).travel(player.global_position, definition.chase_speed, bounds, delta)


func _is_relocating(actor: CombatTarget) -> bool:
	return actor.tactical_airborne or String(_roles.get(actor.stable_id, "")) in ["retreat", "relief", "cover"]


func _advance_retreat(delta: float, members: Array[CombatTarget] = []) -> void:
	var actors := observer._actors if members.is_empty() else members
	_cover_cooldown = maxf(0.0, _cover_cooldown - delta)
	for wounded: CombatTarget in actors:
		if _cover_cooldown > 0.0 or _roles.values().has("retreat") or _roles.values().has("cover"):
			break
		if _relieved.has(wounded.stable_id) or _is_relocating(wounded) or wounded.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
			continue
		if wounded.resolve.current_resolve > wounded.resolve.maximum_resolve * definition.retreat_resolve_ratio:
			continue
		var refuge := _retreat_destination(wounded, actors)
		if refuge.is_finite():
			_goals[wounded.stable_id] = refuge
			_roles[wounded.stable_id] = "retreat"
			_relieved[wounded.stable_id] = true
			wounded.sfx.play_cue(&"tactical_dash")
			_assign_retreat_cover(wounded, actors)
			_cover_cooldown = definition.retreat_cover_cooldown
			break
	for actor: CombatTarget in actors:
		if not _roles.has(actor.stable_id):
			continue
		if actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
			_roles.erase(actor.stable_id)
			_goals.erase(actor.stable_id)
			continue
		actor.external_patrol_enabled = false
		var goal: Vector2 = _goals[actor.stable_id]
		if not actor.tactical_airborne and actor.global_position.distance_to(goal) < definition.home_tolerance:
			if _roles[actor.stable_id] == "retreat":
				_roles[actor.stable_id] = "reserve"
			else:
				_roles.erase(actor.stable_id)
				actor._patrol_origin_x = actor.position.x
			actor._set_patrolling(false)
		elif _roles[actor.stable_id] != "reserve":
			(_motors[actor.stable_id] as BallTacticalMotor).travel(goal, definition.retreat_speed, zone, delta)


func _assign_retreat_cover(wounded: CombatTarget, actors: Array[CombatTarget]) -> void:
	var candidates: Array[CombatTarget] = []
	for actor: CombatTarget in actors:
		if actor == wounded or _roles.has(actor.stable_id) or actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
			continue
		if actor.resolve.current_resolve <= actor.resolve.maximum_resolve * definition.retreat_resolve_ratio:
			continue
		if actor.global_position.distance_to(wounded.global_position) <= definition.retreat_cover_radius:
			candidates.append(actor)
	candidates.sort_custom(func(a: CombatTarget, b: CombatTarget) -> bool: return a.global_position.distance_squared_to(wounded.global_position) < b.global_position.distance_squared_to(wounded.global_position))
	var assigned: Array[Vector2] = []
	for actor: CombatTarget in candidates:
		if assigned.size() >= definition.retreat_cover_count:
			break
		var motor := _motors[actor.stable_id] as BallTacticalMotor
		var best := Vector2(INF, INF)
		var score := INF
		for surface: Dictionary in motor._surfaces(zone):
			for side: float in [0.0, -1.0, 1.0]:
				var target := Vector2(clampf(wounded.global_position.x + side * definition.personal_space * 1.3, float(surface.left), float(surface.right)), float(surface.y))
				var point := PhysicsPointQueryParameters2D.new()
				point.position = target
				point.collision_mask = 1
				if not actor.get_world_2d().direct_space_state.intersect_point(point).is_empty():
					continue
				if assigned.any(func(point: Vector2) -> bool: return point.distance_to(target) < definition.personal_space):
					continue
				if motor.route_to(target, zone).is_empty():
					continue
				var distance := target.distance_to(wounded.global_position)
				if distance < score:
					score = distance
					best = target
		if best.is_finite():
			_roles[actor.stable_id] = "cover"
			_goals[actor.stable_id] = best
			assigned.append(best)
			actor.sfx.play_cue(&"tactical_dash")


func _retreat_destination(wounded: CombatTarget, members: Array[CombatTarget] = []) -> Vector2:
	var actors := observer._actors if members.is_empty() else members
	var motor := _motors[wounded.stable_id] as BallTacticalMotor
	var surfaces := motor._surfaces(zone)
	var best := Vector2(INF, INF)
	var best_comrade_distance := -INF
	var wounded_distance := wounded.global_position.distance_to(player.global_position)
	for comrade: CombatTarget in actors:
		if comrade == wounded or _is_relocating(comrade) or comrade.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR:
			continue
		var distance := comrade.global_position.distance_to(player.global_position)
		if distance <= best_comrade_distance:
			continue
		var away := signf(comrade.global_position.x - player.global_position.x)
		if is_zero_approx(away):
			continue
		for surface: Dictionary in surfaces:
			if absf(float(surface.y) - comrade.global_position.y) > definition.home_tolerance or comrade.global_position.x < float(surface.left) - BallTacticalMotor.FEET or comrade.global_position.x > float(surface.right) + BallTacticalMotor.FEET:
				continue
			for side: float in [away, -away]:
				var point := Vector2(clampf(comrade.global_position.x + side * definition.personal_space, float(surface.left), float(surface.right)), float(surface.y))
				if point.distance_to(player.global_position) < wounded_distance + definition.retreat_safety_gain:
					continue
				var occupied := false
				for other: CombatTarget in observer._actors:
					if other == wounded:
						continue
					var other_goal: Vector2 = _goals.get(other.stable_id, other.global_position)
					if point.distance_to(other.global_position) < definition.personal_space * 0.8 or point.distance_to(other_goal) < definition.personal_space * 0.8:
						occupied = true
						break
				if occupied or motor.route_to(point, zone).is_empty():
					continue
				best = point
				best_comrade_distance = distance
				break
	return best


func _advance_raiders(delta: float, members: Array[CombatTarget] = [], tick_clock: bool = true) -> void:
	var actors := observer._actors if members.is_empty() else members
	var engaging := false
	for actor: CombatTarget in actors:
		var id := actor.stable_id
		_contacts[id] = maxf(0.0, float(_contacts.get(id, 0.0)) - delta)
		if actor.conflict_state.current_state in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
			continue
		var home: Vector2 = _homes[id]
		var in_reach := player_in_zone() and absf(player.global_position.x - home.x) <= definition.pursuit_radius and actor.global_position.distance_to(player.global_position) <= definition.activation_range
		if not in_reach and (actor.conflict_state.current_state == ConflictStateComponent.State.AGGRESSOR or actor.global_position.distance_to(home) > actor.patrol_distance + definition.home_tolerance):
			_returning[id] = true
		if _returning.has(id):
			actor.external_patrol_enabled = false
			_raid_warnings.erase(id)
			if not actor.tactical_airborne and actor.global_position.distance_to(home) <= definition.home_tolerance:
				actor.conflict_state.disengage_at_home()
				actor.conflict_state.cancel_threat()
				actor._set_patrolling(false)
				_returning.erase(id)
			else:
				(_motors[id] as BallTacticalMotor).travel(home, definition.return_speed, zone, delta)
			continue
		if not in_reach:
			_raid_warnings.erase(id)
			actor.conflict_state.cancel_threat()
			continue
		engaging = true
		actor.external_patrol_enabled = false
		actor.conflict_state.begin_threatening()
		_raid_warnings[id] = float(_raid_warnings.get(id, 0.0)) + delta
		if float(_raid_warnings[id]) < definition.warning_seconds:
			continue
		_chase(actor, delta)
		if actor.global_position.distance_to(player.global_position) <= definition.commitment_range and _commit(actor, ConflictStateComponent.AggressorReason.FORCED_CONFISCATION):
			try_contact(actor)
	if tick_clock and started and engaging:
		remaining = maxf(0.0, remaining - delta)
		if is_zero_approx(remaining):
			finish(&"survive_ceasefire")


func try_contact(actor: CombatTarget) -> bool:
	if _mixed_budget and active_attack_count() >= 2:
		return false
	if _returning.has(actor.stable_id):
		return false
	if restoring or observer.is_resolved() or not player_in_zone() or actor.conflict_state.current_state != ConflictStateComponent.State.AGGRESSOR or float(_contacts.get(actor.stable_id, 0.0)) > 0.0 or actor.global_position.distance_to(player.global_position) > definition.contact_radius:
		return false
	var receiver := player.get_node("EffectReceiver") as EffectReceiverComponent
	var epoch := _restore_epoch
	var previous_cue := player.damage_feedback_cue
	player.damage_feedback_cue = &"contact_hit"
	var permission := receiver.receive_effect(actor.identity, EffectContext.encounter_effect(EffectContext.EffectType.KINETIC_DAMAGE, EffectContext.Origin.DIRECT), definition.contact_damage)
	player.damage_feedback_cue = previous_cue
	if not permission.allowed or epoch != _restore_epoch or player.health.current_health <= 0.0:
		return false
	_contacts[actor.stable_id] = definition.contact_cooldown
	if _mixed_budget:
		_contact_windows[actor.stable_id] = 0.35
	var stolen_count: int = 0
	if player.inventory != null:
		for item: String in definition.stolen_items:
			var data: Dictionary = player.inventory.profile.items.get(item, {})
			if data.is_empty() or bool(data.get("protected", false)):
				continue
			var amount := mini(player.inventory.count(item), mini(int(definition.stolen_items[item]), int(definition.theft_limit.get(item, 0)) - int(stolen.get(item, 0))))
			if amount > 0 and player.inventory.spend(item, amount):
				stolen[item] = int(stolen.get(item, 0)) + amount
				var actor_id := String(actor.stable_id)
				var actor_stolen: Dictionary = stolen_by_actor.get(actor_id, {})
				actor_stolen[item] = int(actor_stolen.get(item, 0)) + amount
				stolen_by_actor[actor_id] = actor_stolen
				stolen_count += amount
	if stolen_count > 0:
		if definition.theft_effect != null:
			var burst := definition.theft_effect.instantiate() as TheftBurst
			player.add_child(burst)
			burst.configure(player.global_position, actor.global_position)
		if actor.sfx != null:
			actor.sfx.play_cue(&"theft")
	return true


func finish(resolution: StringName) -> void:
	if observer.is_resolved() or not started or restoring or resolution not in observer.allowed_resolutions:
		return
	# Currency is immediate; WorldLootDrops releases stolen property on resolution.
	if player.inventory != null:
		var reward := definition.reward_sats
		if resolution == &"survive_ceasefire":
			reward += definition.no_attack_bonus if not dealt_damage else 0
			reward += definition.no_hit_bonus if not received_damage else 0
		player.inventory.grant_once("ceasefire:" + String(observer.encounter_id), {}, reward)
	for actor: CombatTarget in observer._actors:
		actor.stop_behavior()
		actor.tactical_moving = false
		if actor.conflict_state.begin_surrender():
			actor._surrender_remaining = 0.8
		elif actor.conflict_state.current_state == ConflictStateComponent.State.THREATENING:
			actor.conflict_state.cancel_threat()
		for node: Node in actor.get_parent().get_children():
			if node is HostileBolt and (node as HostileBolt).source_identity == actor.identity:
				node.queue_free()
	observer.try_resolve(resolution)


func _on_defensive_effect(_permission: TargetPermission, amount: float) -> void:
	if not restoring and started and not observer.is_resolved() and amount > 0.0:
		dealt_damage = true


func _on_health_changed(current: float, _maximum: float) -> void:
	if not restoring and started and player_in_zone() and current < _health_before:
		received_damage = true
		damage_events += 1
	_health_before = current


func _update_hud() -> void:
	_panel.visible = player_in_zone() and not observer.is_resolved()
	var screen_y := player.get_global_transform_with_canvas().origin.y
	_panel.position.y = maxf(360.0, 720.0 - _panel.size.y - 16.0) if screen_y < 400.0 else 125.0
	_bar.value = definition.duration - remaining
	var instruction := "Una rendición retira al grupo." if definition.any_surrender_resolves else "Esquiva el robo o ríndelos."
	if definition.mode == CeasefireChallengeDefinition.AttackMode.AUTONOMOUS_FLANK:
		instruction = "Rompe el cerco o resiste."
	elif definition.mode == CeasefireChallengeDefinition.AttackMode.MARKED_PULSE:
		instruction = "Sal de la marca."
	elif definition.mode == CeasefireChallengeDefinition.AttackMode.MIXED_STAGES:
		var stage := 0
		for delay: float in definition.stage_delays:
			if _stage_elapsed >= delay:
				stage += 1
		instruction = "ETAPA %d/%d · TREGUA COMPARTIDA" % [stage, definition.stage_delays.size()]
		if stage < definition.stage_delays.size():
			instruction += "\nSIGUIENTE: %s EN %.1f s" % [String(definition.group_profiles[stage].title), maxf(0.0, definition.stage_delays[stage] - _stage_elapsed)]
	_label.text = "%s\n%s\n%s" % [definition.title, "ALTO EL FUEGO EN %.1f s" % remaining if started else "ADVERTENCIA · aún no puedes atacar", instruction]
	if started and not can_advance_ceasefire() and definition.ceasefire_core_fraction > 0.0:
		var direction := "DERECHA" if player.global_position.x < ceasefire_bounds().x else "IZQUIERDA"
		_label.text += "\nTREGUA PAUSADA · ve a la " + direction
	if not stolen.is_empty():
		_label.text += "\nRecoge el paquete al resolver."
	for formation: Dictionary in _encirclements.values():
		if bool(formation.get("armed", false)):
			_label.text += "\nCERCO CERRADO · cruza un flanco."
			break
		if float(formation.get("notice", 0.0)) > 0.0:
			_label.text += "\nCERCO ROTO · se reagrupan."
			break
	if _roles.values().has("retreat"):
		_label.text += "\nRETIRADA CUBIERTA · busca otro ángulo." if _roles.values().has("cover") else "\nRETIRADA · busca refugio."


func capture_runtime_state() -> Dictionary:
	var motion: Dictionary = {}
	for id: StringName in _motors:
		motion[id] = (_motors[id] as BallTacticalMotor).capture_runtime_state()
	return {"encirclements": _encirclements.duplicate(true), "cover_cooldown": _cover_cooldown, "started": started, "remaining": remaining, "dealt_damage": dealt_damage, "received_damage": received_damage, "damage_events": damage_events, "stolen": stolen.duplicate(true), "stolen_by_actor": stolen_by_actor.duplicate(true), "turn": _turn, "turn_clock": _turn_clock, "warning": _warning, "contacts": _contacts.duplicate(true), "roles": _roles.duplicate(), "goals": _goals.duplicate(), "relieved": _relieved.duplicate(), "returning": _returning.duplicate(), "raid_warnings": _raid_warnings.duplicate(), "motion": motion, "surrender_awards": _surrender_awards.duplicate(), "surrender_bonus_used": _surrender_bonus_used, "group_turns": _group_turns.duplicate(true), "stage_elapsed": _stage_elapsed, "contact_windows": _contact_windows.duplicate(), "pulse": pulse.capture() if pulse != null else {}}


func restore_runtime_state(state: Dictionary) -> void:
	_encirclements = (state.get("encirclements", {}) as Dictionary).duplicate(true)
	_restore_epoch += 1
	_stage_elapsed = maxf(0.0, float(state.get("stage_elapsed", 0.0)))
	_contact_windows = (state.get("contact_windows", {}) as Dictionary).duplicate()
	_group_turns = (state.get("group_turns", {}) as Dictionary).duplicate(true)
	if pulse != null:
		pulse.restore(state.get("pulse", {}))
	_surrender_awards = (state.get("surrender_awards", {}) as Dictionary).duplicate()
	_surrender_bonus_used = clampf(float(state.get("surrender_bonus_used", 0.0)), 0.0, definition.surrender_bonus_cap)
	started = bool(state.get("started", false))
	remaining = clampf(float(state.get("remaining", definition.duration)), 0.0, definition.duration)
	dealt_damage = bool(state.get("dealt_damage", false))
	received_damage = bool(state.get("received_damage", false))
	damage_events = maxi(0, int(state.get("damage_events", 0)))
	stolen = (state.get("stolen", {}) as Dictionary).duplicate(true)
	stolen_by_actor = (state.get("stolen_by_actor", {}) as Dictionary).duplicate(true)
	_turn = int(state.get("turn", 0))
	_turn_clock = float(state.get("turn_clock", 0.0))
	_warning = float(state.get("warning", 0.0))
	_contacts = (state.get("contacts", {}) as Dictionary).duplicate(true)
	_cover_cooldown = maxf(0.0, float(state.get("cover_cooldown", 0.0)))
	_roles = (state.get("roles", {}) as Dictionary).duplicate()
	_goals = (state.get("goals", {}) as Dictionary).duplicate()
	# Old checkpoints may contain a replacement heading to the wounded post.
	# Keep physical airborne motion, but never resume that obsolete order.
	for id: Variant in _roles.keys():
		if _roles[id] == "relief":
			_roles.erase(id)
			_goals.erase(id)
	_relieved = (state.get("relieved", {}) as Dictionary).duplicate()
	_returning = (state.get("returning", {}) as Dictionary).duplicate()
	_raid_warnings = (state.get("raid_warnings", {}) as Dictionary).duplicate()
	for id: StringName in _motors:
		(_motors[id] as BallTacticalMotor).restore_runtime_state((state.get("motion", {}) as Dictionary).get(id, {}))
	_health_before = player.health.current_health
