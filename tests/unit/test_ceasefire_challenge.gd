extends GdUnitTestSuite


class RelaySoundRecorder extends GameplaySfxEmitter:
	var dash_count: int = 0
	var theft_count: int = 0
	var cues: Array[StringName] = []

	func play_cue(cue_id: StringName) -> bool:
		cues.append(cue_id)
		if cue_id == &"tactical_dash":
			dash_count += 1
		if cue_id == &"theft":
			theft_count += 1
		return true


func _build() -> LevelBuilder:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	level.set_process(false)
	level._player.set_physics_process(false)
	for node: Node in level.find_children("*", "", true, false):
		if node is CombatTarget:
			node.set_process(false)
		elif node is CeasefireChallenge:
			node.set_physics_process(false)
	assert_bool(level.last_validation.is_valid()).is_true()
	return level


func _challenge(level: LevelBuilder, id: String) -> CeasefireChallenge:
	return (level.get_node("Generated/EncounterObservers/" + id) as EncounterRuntimeObserver).challenge


func test_collective_starts_only_after_attack_and_one_surrender_releases_group() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_depot_patrol")
	assert_int(challenge.observer._actors.size()).is_equal(3)
	var actor := challenge.observer._actors[0]
	level._player.global_position = actor.global_position - Vector2(100, 0)
	challenge.advance(0.1)
	assert_bool(challenge.started).is_false()
	var context := EffectContext.offensive(EffectContext.EffectType.KINETIC_DAMAGE)
	assert_bool(actor.receiver.receive_effect(level._player.get_node("Identity"), context, 100).allowed).is_false()
	challenge.advance(1.3)
	assert_bool(challenge.started).is_true()
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
	for member: CombatTarget in challenge.observer._actors:
		assert_int(member.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
		assert_int(member.conflict_state.aggressor_reason).is_equal(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
		assert_bool(TargetValidity.evaluate(level._player.get_node("Identity"), member.receiver, context).allowed).is_true()
	var other_group := _challenge(level, "encounter_dispatch_ancom")
	for member: CombatTarget in other_group.observer._actors:
		assert_int(member.conflict_state.current_state).is_equal(ConflictStateComponent.State.NEUTRAL)
	assert_bool(actor.receiver.receive_effect(level._player.get_node("Identity"), context, 100).allowed).is_true()
	challenge.advance(0.01)
	assert_bool(challenge.observer.is_resolved()).is_true()
	assert_bool(challenge.dealt_damage).is_true()
	assert_int(level._player.inventory.satoshis).is_equal(20)
	for member: CombatTarget in challenge.observer._actors:
		assert_bool(member.receiver.receive_effect(level._player.get_node("Identity"), context, 1).allowed).is_false()


func test_timer_pauses_outside_zone_and_clean_survival_pays_once() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_depot_patrol")
	level._player.global_position = challenge.observer._actors[0].global_position - Vector2(100, 0)
	challenge.advance(1.3)
	var remaining := challenge.remaining
	level._player.position.x = challenge.zone.x - 1.0
	challenge.advance(100)
	assert_float(challenge.remaining).is_equal(remaining)
	assert_bool(challenge.observer.is_resolved()).is_false()
	level._player.position.x = challenge.zone.x + 20.0
	challenge.advance(remaining)
	assert_bool(challenge.observer.is_resolved()).is_true()
	assert_int(level._player.inventory.satoshis).is_equal(60)
	challenge.finish(&"survive_ceasefire")
	assert_int(level._player.inventory.satoshis).is_equal(60)


func test_collectives_use_multiple_supported_heights_and_bounded_patrols() -> void:
	var level := _build()
	await get_tree().physics_frame
	await get_tree().physics_frame
	for id: String in ["encounter_depot_patrol", "encounter_dispatch_ancom", "crew_ancom"]:
		var challenge := _challenge(level, id)
		var heights: Dictionary = {}
		for actor: CombatTarget in challenge.observer._actors:
			heights[actor.position.y] = true
			var origin := actor.position
			var moved := false
			for frame: int in 90:
				actor._update_patrol(0.1)
				moved = moved or absf(actor.position.x - origin.x) > 1.0
				assert_float(absf(actor.position.x - origin.x)).is_less_equal(actor.patrol_distance + 0.01)
				assert_float(actor.position.y).is_equal_approx(origin.y, 0.01)
			assert_bool(moved).is_true()
			actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
			actor.conflict_state.begin_surrender()
			var stopped := actor.position
			actor._update_patrol(1.0)
			assert_vector(actor.position).is_equal(stopped)
		assert_int(heights.size()).is_greater_equal(3)


func test_police_patrols_during_aggression_and_stops_at_edges_and_walls() -> void:
	var level := _build()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var actor := (level.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver)._actors[0]
	actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	var origin := actor.position
	actor._update_patrol(0.1)
	assert_float(actor.position.x).is_greater(origin.x)
	assert_str(actor.presentation_state_id()).is_equal("move")
	actor._begin_attack_visual()
	var firing := actor.position
	actor._update_patrol(0.1)
	assert_vector(actor.position).is_equal(firing)
	actor.position = level._grounded_placement(2630, 650, WorldPropPlacement.BALL_ORIGIN_TO_FLOOR)
	var edge := actor.position
	assert_bool(actor.try_grounded_step(2660)).is_false()
	assert_vector(actor.position).is_equal(edge)
	actor.position = level._grounded_placement(1070, 650, WorldPropPlacement.BALL_ORIGIN_TO_FLOOR)
	var before_wall := actor.position
	assert_bool(actor.try_grounded_step(1130)).is_false()
	assert_vector(actor.position).is_equal(before_wall)


func test_explicit_enemy_positions_validate_count_bounds_and_fields() -> void:
	var level := _build()
	for invalid: Array in [[{"x": 1, "y": 1}], [{"x": -1, "y": 630}, {"x": 6660, "y": 550}, {"x": 6810, "y": 630}, {"x": 6970, "y": 575}, {"x": 7230, "y": 500}], [{"x": 6480, "y": 630, "script": "invalid"}, {"x": 6660, "y": 550}, {"x": 6810, "y": 630}, {"x": 6970, "y": 575}, {"x": 7230, "y": 500}]]:
		var data := level.loaded_spec.data.duplicate(true)
		for encounter: Dictionary in data.encounters:
			if encounter.id == "encounter_depot_patrol":
				encounter.enemy_positions = invalid
		assert_bool(LevelValidator.validate(LevelSpec.new(data, "test_positions"), level.registry).is_valid()).is_false()


func test_medkit_and_machine_cannot_resolve_new_challenges() -> void:
	var level := _build()
	var ego := _challenge(level, "encounter_storage_cache")
	(level.get_node("Generated/Resources/pickup_storage_health") as DebugPickup)._on_body_entered(level._player)
	assert_bool(ego.observer.is_resolved()).is_false()
	assert_object(level.get_node_or_null("Generated/RuleObjects/signal_depot_truce")).is_null()
	var group := _challenge(level, "encounter_depot_patrol")
	group.observer._on_rule_state_changed(&"", &"", &"available", &"occupied", &"")
	assert_bool(group.observer.is_resolved()).is_false()


func test_contact_theft_is_limited_protects_keys_and_returns_property() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_storage_cache")
	challenge.definition = challenge.definition.duplicate(true)
	challenge.definition.stolen_items["production_key"] = 1
	challenge.definition.theft_limit["production_key"] = 1
	var inventory := level._player.inventory
	inventory.grant_once("test", {"trade_parts": 20, "production_key": 1, "service_parts": 10})
	var actor := challenge.observer._actors[0]
	level._player.global_position = actor.global_position
	assert_bool(challenge.try_contact(actor)).is_false()
	challenge._commit(actor, ConflictStateComponent.AggressorReason.FORCED_CONFISCATION)
	for attempt: int in 5:
		challenge._contacts.clear()
		challenge.try_contact(actor)
	assert_int(inventory.count("light_ammo")).is_equal(96)
	assert_int(inventory.count("trade_parts")).is_equal(14)
	assert_int(inventory.count("production_key")).is_equal(1)
	assert_int(inventory.count("service_parts")).is_equal(10)
	assert_float(level._player.health.current_health).is_equal(96.0)
	assert_bool(challenge.received_damage).is_true()
	assert_bool(challenge.try_contact(actor)).is_false()
	challenge.finish(&"survive_ceasefire")
	assert_int(inventory.count("light_ammo")).is_equal(96)
	var loot := (level.get_node("Generated/Economy") as WorkshopEconomy).loot
	var recovery := loot.drops["restitution:encounter_storage_cache"] as DebugPickup
	assert_bool(recovery.is_available()).is_true()
	recovery.advance_drop(1.0)
	recovery._on_body_entered(level._player)
	assert_int(inventory.count("light_ammo")).is_equal(120)
	assert_int(inventory.count("trade_parts")).is_equal(20)
	assert_int(inventory.satoshis).is_equal(40)


func test_theft_feedback_only_on_successful_transfer_and_cleans_up() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_storage_cache")
	var actor := challenge.observer._actors[0]
	var recorder := RelaySoundRecorder.new()
	actor.add_child(recorder)
	actor.sfx = recorder
	var player_sound := RelaySoundRecorder.new()
	level._player.add_child(player_sound)
	level._player.sfx = player_sound
	level._player.global_position = actor.global_position - Vector2(25, 0)
	assert_bool(challenge.try_contact(actor)).is_false()
	assert_int(recorder.theft_count).is_equal(0)
	challenge._commit(actor, ConflictStateComponent.AggressorReason.FORCED_CONFISCATION)
	assert_bool(challenge.try_contact(actor)).is_true()
	assert_int(recorder.theft_count).is_equal(1)
	var bursts := level._player.find_children("*", "TheftBurst", false, false)
	assert_int(bursts.size()).is_equal(1)
	var burst := bursts[0] as TheftBurst
	assert_vector(burst.global_position).is_equal(level._player.global_position)
	assert_vector(burst.destination).is_equal(Vector2(25, 0))
	assert_bool(challenge.try_contact(actor)).is_false()
	assert_int(recorder.theft_count).is_equal(1)
	challenge._contacts.clear()
	challenge.stolen = challenge.definition.theft_limit.duplicate()
	level._player.health._invulnerability_remaining = 0.0
	assert_bool(challenge.try_contact(actor)).is_true()
	assert_int(recorder.theft_count).is_equal(1)
	assert_int(player_sound.cues.count(&"contact_hit")).is_equal(2)
	assert_bool(&"hurt" in player_sound.cues).is_false()
	assert_bool(&"fire" in player_sound.cues).is_false()
	assert_str(String(level._player.damage_feedback_cue)).is_equal("hurt")
	burst._process(burst.duration)
	assert_bool(burst.is_queued_for_deletion()).is_true()


func test_raiders_require_all_surrenders_unlike_collective() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_storage_cache")
	assert_int(challenge.observer._actors.size()).is_equal(2)
	level._player.global_position = challenge.observer._actors[0].global_position
	for actor: CombatTarget in challenge.observer._actors:
		challenge._commit(actor, ConflictStateComponent.AggressorReason.FORCED_CONFISCATION)
	challenge.observer._actors[0].conflict_state.begin_surrender()
	challenge.advance(0.0)
	assert_bool(challenge.observer.is_resolved()).is_false()
	challenge.observer._actors[1].conflict_state.begin_surrender()
	challenge.advance(0.0)
	assert_bool(challenge.observer.is_resolved()).is_true()


func test_checkpoint_restores_timer_theft_and_no_duplicate_reward() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_storage_cache")
	var actor := challenge.observer._actors[0]
	level._player.position = actor.position
	challenge._commit(actor, ConflictStateComponent.AggressorReason.FORCED_CONFISCATION)
	challenge.try_contact(actor)
	challenge.remaining = 13.0
	level.activate_checkpoint(&"test_raid", level._player.position)
	challenge.finish(&"survive_ceasefire")
	level.retry_from_checkpoint()
	assert_bool(challenge.observer.is_resolved()).is_false()
	assert_float(challenge.remaining).is_equal(13.0)
	assert_int(level._player.inventory.count("light_ammo")).is_equal(112)
	assert_int(int(challenge.stolen.light_ammo)).is_equal(8)
	assert_bool(challenge.received_damage).is_true()
	challenge.finish(&"survive_ceasefire")
	assert_int(level._player.inventory.count("light_ammo")).is_equal(112)
	var loot := (level.get_node("Generated/Economy") as WorkshopEconomy).loot
	level.activate_checkpoint(&"uncollected_restitution", level._player.position)
	level.retry_from_checkpoint()
	var recovery := loot.drops["restitution:encounter_storage_cache"] as DebugPickup
	assert_bool(recovery.is_available()).is_true()
	assert_float(recovery.lifetime_seconds).is_equal(0.0)
	recovery.advance_drop(1.0)
	recovery._on_body_entered(level._player)
	assert_int(level._player.inventory.count("light_ammo")).is_equal(120)
	assert_int(level._player.inventory.satoshis).is_equal(40)
	level.activate_checkpoint(&"collected_restitution", level._player.position)
	level.retry_from_checkpoint()
	assert_bool(loot.drops.has("restitution:encounter_storage_cache")).is_false()
	assert_int(level._player.inventory.count("light_ammo")).is_equal(120)


func test_new_encounters_increase_roster_and_gate_every_exit() -> void:
	var level := _build()
	for entry: Array in [["encounter_depot_patrol", 3], ["encounter_dispatch_ancom", 6], ["crew_ancom", 7], ["encounter_storage_cache", 2], ["encounter_dispatch_egoist", 3], ["crew_egoist", 4]]:
		var challenge := _challenge(level, entry[0])
		assert_int(challenge.observer._actors.size()).is_equal(entry[1])
		var gate := level.get_node("Generated/Gates/gate_" + entry[0]) as AccessGate
		assert_bool(gate.is_open()).is_false()
		level._player.global_position = challenge.observer._actors[0].global_position
		challenge._commit(challenge.observer._actors[0], ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
		challenge.finish(&"survive_ceasefire")
		assert_bool(gate.is_open()).is_true()


func test_invalid_challenge_timing_is_rejected() -> void:
	var definition := CeasefireChallengeDefinition.new()
	assert_bool(definition.is_valid()).is_true()
	definition.duration = 0.0
	assert_bool(definition.is_valid()).is_false()


func test_raider_pursuit_moves_on_terrain_without_merging_into_player() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_storage_cache")
	var actor := challenge.observer._actors[0]
	level._player.position = actor.position - Vector2(100, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var origin := actor.position
	challenge._chase(actor, 0.1)
	assert_float(actor.position.x).is_less(origin.x)
	assert_float(actor.position.y).is_equal_approx(origin.y, 0.1)
	actor.position = level._player.position + Vector2(49, 0)
	origin = actor.position
	challenge._chase(actor, 0.1)
	assert_vector(actor.position).is_equal(origin)


func test_defending_does_not_restart_timer_and_pause_stops_processing() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_depot_patrol")
	level._player.position = challenge.observer._actors[0].position - Vector2(100, 0)
	challenge.advance(1.3)
	challenge.advance(4.0)
	var before := challenge.remaining
	challenge.observer._actors[0].receiver.receive_effect(level._player.get_node("Identity"), EffectContext.offensive(), 1.0)
	assert_float(challenge.remaining).is_equal(before)
	get_tree().paused = true
	assert_bool(challenge.can_process()).is_false()
	get_tree().paused = false


func test_wounded_collective_relay_moves_physically_without_healing_and_one_surrender_still_wins() -> void:
	var level := _build()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var challenge := _challenge(level, "encounter_depot_patrol")
	var wounded := challenge.observer._actors[0]
	level._player.global_position = wounded.global_position - Vector2(100, 0)
	challenge.advance(1.3)
	var origin := wounded.global_position
	var sound := RelaySoundRecorder.new()
	wounded.add_child(sound)
	wounded.sfx = sound
	wounded.receiver.receive_effect(level._player.get_node("Identity"), EffectContext.offensive(), 10.0)
	challenge.advance(0.016)
	assert_str(challenge._roles.get(wounded.stable_id, "")).is_equal("retreat")
	assert_bool(challenge._roles.values().has("relief")).is_true()
	var replacement_id: StringName = challenge._roles.find_key("relief")
	var replacement := (challenge._motors[replacement_id] as BallTacticalMotor).actor
	var replacement_goal: Vector2 = challenge._goals[replacement_id]
	assert_bool(challenge.observer.is_resolved()).is_false()
	var resolve_before := wounded.resolve.current_resolve
	var jumped := false
	for frame: int in 60:
		challenge._advance_relay(1.0 / 60.0)
		jumped = jumped or wounded.tactical_airborne
		await get_tree().physics_frame
	assert_bool(jumped).is_true()
	assert_float(wounded.global_position.distance_to(origin)).is_greater(80.0)
	assert_float(wounded.global_position.distance_to(challenge._goals[wounded.stable_id])).is_less(12.0)
	assert_float(replacement.global_position.distance_to(replacement_goal)).is_less(12.0)
	assert_int(sound.dash_count).is_equal(1)
	challenge.restore_runtime_state(challenge.capture_runtime_state())
	challenge._advance_relay(1.0 / 60.0)
	assert_int(sound.dash_count).is_equal(1)
	assert_float(wounded.resolve.current_resolve).is_equal(resolve_before)
	assert_bool(challenge.observer.is_resolved()).is_false()
	wounded.receiver.receive_effect(level._player.get_node("Identity"), EffectContext.offensive(), 100.0)
	challenge.advance(0.016)
	assert_bool(challenge.observer.is_resolved()).is_true()
	assert_int(level._player.inventory.satoshis).is_equal(20)


func test_raider_returns_on_foot_pauses_clock_and_warns_again_without_healing() -> void:
	var level := _build()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var challenge := _challenge(level, "encounter_storage_cache")
	var actor := challenge.observer._actors[0]
	var home: Vector2 = challenge._homes[actor.stable_id]
	level._player.global_position = home - Vector2(120, 0)
	challenge.advance(1.3)
	for frame: int in 15:
		challenge.advance(1.0 / 60.0)
	assert_float(actor.global_position.distance_to(home)).is_greater(20.0)
	actor.resolve.reduce(1.0)
	var health_before := actor.resolve.current_resolve
	challenge.stolen = {"light_ammo": 8}
	level._player.global_position.x = challenge.zone.x - 100.0
	var clock_before := challenge.remaining
	var before_return := actor.global_position
	challenge.advance(1.0 / 60.0)
	assert_bool(challenge._returning.has(actor.stable_id)).is_true()
	assert_float(actor.global_position.distance_to(before_return)).is_less(4.0)
	for frame: int in 150:
		challenge.advance(1.0 / 60.0)
		await get_tree().physics_frame
	assert_float(actor.global_position.distance_to(home)).is_less_equal(challenge.definition.home_tolerance)
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.NEUTRAL)
	assert_float(actor.resolve.current_resolve).is_equal(health_before)
	assert_float(challenge.remaining).is_equal(clock_before)
	assert_int(challenge.stolen.light_ammo).is_equal(8)
	assert_bool(challenge.observer.is_resolved()).is_false()
	level._player.global_position = home - Vector2(100, 0)
	challenge.advance(0.1)
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.THREATENING)
	assert_bool(TargetValidity.evaluate(level._player.get_node("Identity"), actor.receiver, EffectContext.offensive()).allowed).is_false()
	challenge.advance(1.3)
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)


func test_wounded_ball_escapes_early_and_survives_followup_hits() -> void:
	var level := _build()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var challenge := _challenge(level, "encounter_depot_patrol")
	var actor := challenge.observer._actors[0]
	level._player.global_position = actor.global_position - Vector2(100, 0)
	challenge.advance(1.3)
	assert_float(actor.resolve.maximum_resolve).is_equal(60.0)
	var origin := actor.global_position
	var context := EffectContext.offensive()
	# Two light hits trigger retreat; two further hits cannot end the group.
	for hit: int in 2:
		actor.receiver.receive_effect(level._player.get_node("Identity"), context, 5.0)
	challenge._advance_relay(1.0 / 60.0)
	assert_str(challenge._roles.get(actor.stable_id, "")).is_equal("retreat")
	assert_str(String(challenge._roles.find_key("relief"))).is_equal(String(challenge.observer._actors[1].stable_id))
	for frame: int in 12:
		challenge._advance_relay(1.0 / 60.0)
		await get_tree().physics_frame
	assert_float(actor.global_position.distance_to(origin)).is_greater(100.0)
	for hit: int in 2:
		actor.receiver.receive_effect(level._player.get_node("Identity"), context, 5.0)
	assert_float(actor.resolve.current_resolve).is_equal(40.0)
	assert_int(actor.conflict_state.current_state).is_equal(ConflictStateComponent.State.AGGRESSOR)
	assert_bool(challenge.observer.is_resolved()).is_false()


func test_tactical_checkpoint_restores_relay_and_airborne_state() -> void:
	var level := _build()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var challenge := _challenge(level, "encounter_depot_patrol")
	var actor := challenge.observer._actors[0]
	level._player.global_position = actor.global_position - Vector2(100, 0)
	challenge.advance(1.3)
	actor.resolve.reduce(10.0)
	challenge.advance(0.016)
	var motor := challenge._motors[actor.stable_id] as BallTacticalMotor
	for frame: int in 180:
		challenge._advance_relay(1.0 / 60.0)
		await get_tree().physics_frame
		if motor.airborne:
			break
	assert_bool(motor.airborne).is_true()
	var before := challenge.capture_runtime_state()
	level.activate_checkpoint(&"relay_in_flight", level._player.position)
	challenge.finish(&"survive_ceasefire")
	level.retry_from_checkpoint()
	assert_bool(challenge.observer.is_resolved()).is_false()
	assert_str(challenge._roles[actor.stable_id]).is_equal("retreat")
	assert_bool(motor.airborne).is_true()
	assert_vector(motor.velocity).is_equal(before.motion[actor.stable_id].velocity)
	assert_float(actor.resolve.current_resolve).is_equal(50.0)
	assert_int(level._player.inventory.satoshis).is_equal(0)


func test_tactical_jump_rejects_unreachable_arcs_and_solid_walls() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_storage_cache")
	var motor := challenge._motors[challenge.observer._actors[0].stable_id] as BallTacticalMotor
	var source := {"left": 50000.0, "right": 50000.0, "y": 0.0}
	var landing := {"left": 50100.0, "right": 50100.0, "y": 0.0}
	assert_bool(motor._edge(source, {"left": 51000.0, "right": 51000.0, "y": 0.0}, 51000).is_empty()).is_true()
	assert_bool(motor._edge(source, {"left": 50100.0, "right": 50100.0, "y": -500.0}, 50100).is_empty()).is_true()
	assert_bool(motor._edge(source, landing, 50100).is_empty()).is_false()
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24, 500)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = Vector2(50050, -100)
	level.add_child(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(motor._edge(source, landing, 50100).is_empty()).is_true()
	var before := motor._surfaces(challenge.zone).size()
	for surface: DebugPlatform in motor.platforms:
		surface.set_rule_enabled(false)
	assert_int(before).is_greater(0)
	assert_int(motor._surfaces(challenge.zone).size()).is_equal(0)


func test_tactical_motor_lands_across_gap_on_solid_raised_platform() -> void:
	var level := _build()
	var challenge := _challenge(level, "encounter_storage_cache")
	var actor := challenge.observer._actors[0]
	var motor := challenge._motors[actor.stable_id] as BallTacticalMotor
	var source := DebugPlatform.new()
	source.position = Vector2(50000, 600)
	source.size = Vector2(300, 100)
	level.add_child(source)
	var target := DebugPlatform.new()
	target.position = Vector2(50380, 550)
	target.size = Vector2(300, 200)
	level.add_child(target)
	motor.platforms = [source, target]
	actor.global_position = Vector2(50000, 526)
	motor.restore_runtime_state({})
	await get_tree().physics_frame
	await get_tree().physics_frame
	var origin := actor.global_position
	var goal := Vector2(50380, 426)
	var bounds := Vector2(49850, 50530)
	var jumped_sideways := false
	for frame: int in 240:
		motor.travel(goal, 190.0, bounds, 1.0 / 60.0)
		jumped_sideways = jumped_sideways or (motor.airborne and absf(motor.velocity.x) > 20.0)
		await get_tree().physics_frame
		if not motor.airborne and actor.global_position.distance_to(goal) < 12.0:
			break
	assert_bool(jumped_sideways).is_true()
	assert_float(actor.global_position.x - origin.x).is_greater(300.0)
	assert_float(actor.global_position.distance_to(goal)).is_less(12.0)


func test_raiders_reach_first_solid_stair_in_crew_zone() -> void:
	var level := _build()
	var challenge := _challenge(level, "crew_egoist")
	var platform := level.get_node("Generated/Platforms/crew_return_a") as DebugPlatform
	await get_tree().physics_frame
	await get_tree().physics_frame
	var goal := Vector2(platform.global_position.x, platform.global_position.y - platform.size.y * 0.5 + platform.collision_surface_depth - 24.0)
	var reached := false
	for frame: int in 420:
		level._player.global_position = goal
		challenge.advance(1.0 / 60.0)
		await get_tree().physics_frame
		for actor: CombatTarget in challenge.observer._actors:
			if not actor.tactical_airborne and actor.global_position.distance_to(goal) < challenge.definition.contact_radius:
				reached = true
		if reached:
			break
	assert_bool(reached).override_failure_message("Egoist must land on crew_return_a, not jump vertically at its wall").is_true()


func test_raiders_pursue_player_on_each_upper_workshop_platform() -> void:
	for pair: Array in [["encounter_storage_cache", "storage_lift"], ["encounter_dispatch_egoist", "dispatch_service_walkway"], ["crew_egoist", "crew_cache_route"]]:
		var level := _build()
		var challenge := _challenge(level, pair[0])
		var platform := level.get_node("Generated/Platforms/" + pair[1]) as DebugPlatform
		if pair[0] == "crew_egoist":
			var crew := level.get_node("Generated/crew_workshop_coordination") as CrewCoordination
			crew.power_source.interact()
			var economy := level.get_node("Generated/Economy") as WorkshopEconomy
			economy.player.inventory.grant_once("test_service", {"service_parts": 10})
			economy.confirm_service()
			crew.assign_local(1, true)
		platform.set_rule_enabled(true)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var jumped := false
		var reached := false
		var reached_actor: CombatTarget = null
		for frame: int in 480:
			level._player.global_position = Vector2(platform.global_position.x, platform.global_position.y - platform.size.y * 0.5 + platform.collision_surface_depth - 24.0)
			challenge.advance(1.0 / 60.0)
			await get_tree().physics_frame
			for actor: CombatTarget in challenge.observer._actors:
				jumped = jumped or actor.tactical_airborne
				if not actor.tactical_airborne and actor.global_position.distance_to(level._player.global_position) < challenge.definition.contact_radius:
					reached = true
					reached_actor = actor
			if reached:
				break
		assert_bool(jumped).override_failure_message("Must jump: " + pair[0]).is_true()
		assert_bool(reached).override_failure_message("Must reach elevated player: " + pair[0]).is_true()
		if reached_actor != null:
			level._player.global_position.x = challenge.zone.x - 200.0
			var home: Vector2 = challenge._homes[reached_actor.stable_id]
			var motor := challenge._motors[reached_actor.stable_id] as BallTacticalMotor
			var checked_drop_restore := false
			for frame: int in 480:
				challenge.advance(1.0 / 60.0)
				if motor._drop_platform != null and not checked_drop_restore:
					var support := motor._drop_platform
					var state := motor.capture_runtime_state()
					motor.restore_runtime_state({})
					assert_bool(motor.get_collision_exceptions().has(support)).is_false()
					motor.restore_runtime_state(state)
					assert_bool(motor.get_collision_exceptions().has(support)).is_true()
					checked_drop_restore = true
				await get_tree().physics_frame
				if reached_actor.global_position.distance_to(home) <= challenge.definition.home_tolerance and not reached_actor.tactical_airborne:
					break
			assert_float(reached_actor.global_position.distance_to(home)).override_failure_message("Must return from upper route: " + pair[0]).is_less_equal(challenge.definition.home_tolerance)
			assert_bool(checked_drop_restore).is_true()
			assert_object(motor._drop_platform).is_null()
		level.queue_free()
		await get_tree().process_frame
