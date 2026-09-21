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
	]:
		assert_bool(profile.has_cue(cue_id)).is_true()
		assert_object(profile.stream_for(cue_id)).is_not_null()


func test_audio_profile_rejects_unknown_cue() -> void:
	var profile := GameplayAudioProfile.new()
	assert_bool(profile.has_cue(&"unknown")).is_false()
	assert_object(profile.stream_for(&"unknown")).is_null()


func test_gamified_world_cues_use_short_dedicated_retro_assets() -> void:
	var profile := load(PROFILE_PATH) as GameplayAudioProfile
	for cue_id: StringName in [&"threat", &"aggression", &"surrender", &"pickup", &"rule_interaction", &"checkpoint"]:
		var stream := profile.stream_for(cue_id)
		assert_object(stream).is_not_null()
		assert_str(stream.resource_path).contains("/generated/")
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
