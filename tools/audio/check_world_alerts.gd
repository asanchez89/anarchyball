extends SceneTree


func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var level := load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate() as LevelBuilder
	level.start_in_menu = false
	root.add_child(level)
	await process_frame
	level.set_process(false)
	level._player.set_physics_process(false)
	for node: Node in level.find_children("*", "", true, false):
		if node is CombatTarget:
			node.set_process(false)
		if node is CeasefireChallenge:
			node.set_physics_process(false)
	var actor := (level.get_node("Generated/EncounterObservers/encounter_depot_patrol") as EncounterRuntimeObserver)._actors[0]
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	var effect_index := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, capture)
	var passed := true
	var played: Array[StringName] = []
	actor.sfx.cue_played.connect(func(cue: StringName) -> void: played.append(cue))
	var relay := "--relay-dash" in OS.get_cmdline_user_args()
	var positions: Array[float] = [6480.0]
	if not relay:
		positions.append(19200.0)
	for x: float in positions:
		actor.restore_runtime_state({"conflict_state": ConflictStateComponent.State.NEUTRAL})
		actor.position.x = x
		camera.position = actor.position
		camera.force_update_scroll()
		await process_frame
		if relay:
			var challenge := (level.get_node("Generated/EncounterObservers/encounter_depot_patrol") as EncounterRuntimeObserver).challenge
			level._player.position = actor.position - Vector2(100, 0)
			challenge.advance(1.3)
			await create_timer(1.0).timeout
		capture.clear_buffer()
		played.clear()
		if relay:
			actor.resolve.reduce(10.0)
			var challenge := (level.get_node("Generated/EncounterObservers/encounter_depot_patrol") as EncounterRuntimeObserver).challenge
			challenge._advance_relay(1.0 / 60.0)
		else:
			actor.conflict_state.begin_threatening()
		var accepted := played.has(&"tactical_dash" if relay else &"threat")
		await create_timer(0.5).timeout
		var samples := capture.get_buffer(capture.get_frames_available())
		var peak := 0.0
		for sample: Vector2 in samples:
			peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		var aligned := actor.sfx._spatial_voices[0].global_position.is_equal_approx(actor.global_position)
		print("ALERT_PLAYBACK x=", x, " aligned=", aligned, " accepted=", accepted, " samples=", samples.size(), " peak=", peak)
		passed = passed and accepted and aligned and peak > 0.001
	AudioServer.remove_bus_effect(0, effect_index)
	level.queue_free()
	camera.queue_free()
	await process_frame
	await create_timer(0.8).timeout
	quit(0 if passed else 1)
