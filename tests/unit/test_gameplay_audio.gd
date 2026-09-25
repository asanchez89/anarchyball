extends GdUnitTestSuite

const PROFILE_PATH := "res://data/audio/world0_gameplay_audio.tres"


func test_world0_audio_profile_declares_every_runtime_cue() -> void:
	var profile := load(PROFILE_PATH) as GameplayAudioProfile
	assert_object(profile).is_not_null()
	for cue_id: StringName in [
		&"jump", &"fire", &"hurt", &"impact_allowed", &"impact_blocked",
		&"threat", &"aggression", &"surrender", &"pickup", &"gate_open",
		&"rule_interaction", &"contract_state", &"encounter_resolved",
		&"checkpoint", &"boss_phase", &"completion_denied", &"level_complete",
		&"dispute", &"alert_clear", &"neutralized", &"tactical_dash", &"theft", &"contact_hit",
	]:
		assert_bool(profile.has_cue(cue_id)).is_true()
		assert_object(profile.stream_for(cue_id)).is_not_null()


func test_audio_profile_rejects_unknown_cue() -> void:
	var profile := GameplayAudioProfile.new()
	assert_bool(profile.has_cue(&"unknown")).is_false()
	assert_object(profile.stream_for(&"unknown")).is_null()


func test_theft_sound_is_short_and_not_gunfire() -> void:
	var profile := load(PROFILE_PATH) as GameplayAudioProfile
	var stream := profile.theft as AudioStreamWAV
	assert_object(stream).is_not_null()
	assert_float(stream.get_length()).is_equal_approx(0.26, 0.01)
	assert_int(stream.loop_mode).is_equal(AudioStreamWAV.LOOP_DISABLED)
	assert_bool(stream == profile.fire).is_false()
	assert_bool(stream == profile.hurt).is_false()


func test_relay_whoosh_is_short_nonlooping_and_distinct_from_alerts() -> void:
	var profile := load(PROFILE_PATH) as GameplayAudioProfile
	var stream := profile.tactical_dash as AudioStreamWAV
	assert_object(stream).is_not_null()
	assert_float(stream.get_length()).is_equal_approx(0.32, 0.01)
	assert_int(stream.loop_mode).is_equal(AudioStreamWAV.LOOP_DISABLED)
	assert_float(profile.max_duration_for(&"tactical_dash")).is_less_equal(0.4)
	assert_bool(stream == profile.threat).is_false()


func test_gamified_world_cues_use_short_dedicated_retro_assets() -> void:
	var profile := load(PROFILE_PATH) as GameplayAudioProfile
	for cue_id: StringName in [&"threat", &"aggression", &"surrender", &"pickup", &"rule_interaction", &"checkpoint", &"gate_open", &"dispute", &"alert_clear", &"neutralized"]:
		var stream := profile.stream_for(cue_id)
		assert_object(stream).is_not_null()
		assert_str(stream.resource_path).contains("/generated/")
		assert_float(stream.get_length()).is_less_equal(0.5)
	assert_bool(profile.stream_for(&"pickup") == profile.stream_for(&"checkpoint")).is_false()


func test_rapid_fire_retriggers_instead_of_stacking_long_tails() -> void:
	var profile := load(PROFILE_PATH) as GameplayAudioProfile
	assert_bool(profile.should_retrigger(&"fire")).is_true()
	assert_bool(profile.should_retrigger(&"impact_allowed")).is_false()
	assert_float(profile.max_duration_for(&"jump")).is_less_equal(0.4)
	assert_float(profile.max_duration_for(&"contract_state")).is_less_equal(0.7)
	assert_float(profile.max_duration_for(&"level_complete")).is_equal(0.0)


func test_player_feedback_is_global_while_world_actor_feedback_is_spatial() -> void:
	var player_scene := load("res://src/actors/player/player.tscn") as PackedScene
	var player: Node = auto_free(player_scene.instantiate()) as Node
	var player_sfx := player.get_node("Sfx") as GameplaySfxEmitter
	assert_bool(player_sfx.spatial).is_false()

	var target_scene := load("res://src/debug/combat_target.tscn") as PackedScene
	var target: Node = auto_free(target_scene.instantiate()) as Node
	var target_sfx := target.get_node("Sfx") as GameplaySfxEmitter
	assert_bool(target_sfx.spatial).is_true()


func test_menu_resume_suppresses_jump_and_fire_until_controls_are_released() -> void:
	var player_scene := load("res://src/actors/player/player.tscn") as PackedScene
	var player := auto_free(player_scene.instantiate()) as PlayerController
	add_child(player)
	player.suppress_gameplay_input_until_released()
	assert_bool(player.is_gameplay_input_suppressed()).is_true()
	assert_bool(player.probe_launcher.input_enabled).is_false()
	player._update_input_release_guard()
	assert_bool(player.is_gameplay_input_suppressed()).is_false()
	assert_bool(player.probe_launcher.input_enabled).is_true()


class RecordingEmitter extends GameplaySfxEmitter:
	var played: Array[StringName] = []

	func play_cue(cue_id: StringName) -> bool:
		played.append(cue_id)
		return true


func test_enemy_projectiles_sound_at_launch_without_requiring_an_impact() -> void:
	var arena := auto_free(Node2D.new()) as Node2D
	add_child(arena)
	var actor := load("res://src/debug/combat_target.tscn").instantiate() as CombatTarget
	arena.add_child(actor)
	actor.set_process(false)
	var recorder := RecordingEmitter.new()
	actor.add_child(recorder)
	actor.sfx = recorder
	# Presentation alone (including contact/theft actions) is not a gunshot.
	actor._begin_attack_visual()
	actor.player_path = NodePath("MissingPlayer")
	actor._launch_hostile_bolt()
	assert_array(recorder.played).is_empty()
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT]:
		actor._launch_bolt_direction(direction)
		var bolt := arena.get_child(arena.get_child_count() - 1) as HostileBolt
		assert_object(bolt).is_not_null()
		assert_vector(bolt.direction).is_equal(direction)
	# Both shots miss: there is no player or impact callback in this fixture.
	assert_array(recorder.played).contains_exactly([&"fire", &"fire"])


func test_state_transitions_sound_once_and_restore_is_silent() -> void:
	var actor := auto_free(load("res://src/debug/combat_target.tscn").instantiate()) as CombatTarget
	add_child(actor)
	var recorder := RecordingEmitter.new()
	actor.add_child(recorder)
	actor.sfx = recorder
	actor.conflict_state.begin_threatening()
	actor.conflict_state.begin_threatening()
	actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	var snapshot := actor.capture_runtime_state()
	actor.conflict_state.begin_surrender()
	actor.conflict_state.neutralize()
	assert_array(recorder.played).contains_exactly([&"threat", &"aggression", &"surrender"])
	recorder.played.clear()
	actor.restore_runtime_state(snapshot)
	assert_array(recorder.played).is_empty()
	actor.conflict_state.neutralize()
	assert_array(recorder.played).contains_exactly([&"neutralized"])
	actor.conflict_state.reset_conflict(ConflictStateComponent.State.NEUTRAL)
	assert_str(String(recorder.played.back())).is_equal("alert_clear")
	actor.conflict_state.reset_conflict(ConflictStateComponent.State.DISPUTED)
	assert_str(String(recorder.played.back())).is_equal("dispute")


func test_collective_alerts_coalesce_but_other_cues_and_later_transitions_do_not() -> void:
	var viewport := auto_free(SubViewport.new()) as SubViewport
	add_child(viewport)
	var first := GameplaySfxEmitter.new()
	var second := GameplaySfxEmitter.new()
	first.profile = load(PROFILE_PATH)
	second.profile = first.profile
	viewport.add_child(first)
	viewport.add_child(second)
	assert_bool(first.claim_cue_window(&"aggression", 10.0)).is_true()
	assert_bool(second.claim_cue_window(&"aggression", 10.02)).is_false()
	assert_bool(second.claim_cue_window(&"threat", 10.02)).is_true()
	assert_bool(second.claim_cue_window(&"aggression", 10.2)).is_true()
	assert_bool(first.claim_cue_window(&"gate_open", 10.2)).is_true()
	assert_bool(second.claim_cue_window(&"gate_open", 10.2)).is_true()


func test_gate_opening_emits_once_but_restore_and_denied_access_are_silent() -> void:
	var gate := auto_free(AccessGate.new()) as AccessGate
	gate.required_tag = &"encounter_resolution"
	add_child(gate)
	var opened: Array[StringName] = []
	gate.opened.connect(func(id: StringName) -> void: opened.append(id))
	assert_bool(gate.try_open()).is_false()
	gate.restore_open(true)
	assert_array(opened).is_empty()
	gate.restore_open(false)
	assert_bool(gate.open_for_resolution()).is_true()
	assert_bool(gate.open_for_resolution()).is_false()
	assert_int(opened.size()).is_equal(1)
	gate.restore_open(true)
	assert_int(opened.size()).is_equal(1)
	gate.restore_open(false)
	gate.player_tags.append(&"encounter_resolution")
	assert_bool(gate.try_open()).is_true()
	assert_int(opened.size()).is_equal(2)


func test_first_police_challenge_plays_gate_cue_without_repeating_on_retry() -> void:
	var level := auto_free(load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate()) as LevelBuilder
	level.start_in_menu = false
	add_child(level)
	var recorder := RecordingEmitter.new()
	level.add_child(recorder)
	level._audio = recorder
	var observer := level.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver
	observer._actors[0].conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
	observer._actors[0].conflict_state.neutralize()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(recorder.played.count(&"gate_open")).is_equal(1)
	level.activate_checkpoint(&"audio_gate", Vector2(500, 600))
	recorder.played.clear()
	level.retry_from_checkpoint()
	assert_int(recorder.played.count(&"gate_open")).is_equal(0)


func test_spatial_voice_inherits_actor_position_far_from_level_origin() -> void:
	var actor := auto_free(load("res://src/debug/combat_target.tscn").instantiate()) as CombatTarget
	actor.position = Vector2(6480, 658)
	add_child(actor)
	# Headless suppresses audio allocation, but the real transform hierarchy is tested.
	var voice := AudioStreamPlayer2D.new()
	actor.sfx.add_child(voice)
	assert_vector(voice.global_position).is_equal(actor.global_position)
	actor.position = Vector2(19200, 440)
	assert_vector(voice.global_position).is_equal(actor.global_position)
	var profile := load(PROFILE_PATH) as GameplayAudioProfile
	assert_str(profile.threat.resource_path).contains("detection_alert_retro.wav")
	assert_float(float(profile.cue_volume_offsets_db[&"threat"])).is_greater(0.0)
