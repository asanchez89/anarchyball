class_name GameplaySfxEmitter
extends Node2D

signal cue_played(cue_id: StringName)

@export var profile: GameplayAudioProfile
@export_range(1, 8, 1) var voice_count: int = 4
@export_range(0.0, 4096.0, 1.0) var max_distance: float = 1200.0
@export var spatial: bool = true

var _spatial_voices: Array[AudioStreamPlayer2D] = []
var _global_voices: Array[AudioStreamPlayer] = []
var _spatial_voice_cues: Array[StringName] = []
var _global_voice_cues: Array[StringName] = []
var _playback_tokens: Dictionary = {}
var _next_voice: int = 0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for index: int in range(voice_count):
		if spatial:
			var spatial_voice := AudioStreamPlayer2D.new()
			spatial_voice.name = "Voice%d" % index
			spatial_voice.max_distance = max_distance
			spatial_voice.attenuation = 1.0
			add_child(spatial_voice)
			_spatial_voices.append(spatial_voice)
			_spatial_voice_cues.append(&"")
		else:
			var global_voice := AudioStreamPlayer.new()
			global_voice.name = "Voice%d" % index
			add_child(global_voice)
			_global_voices.append(global_voice)
			_global_voice_cues.append(&"")


func play_cue(cue_id: StringName) -> bool:
	if profile == null or (_spatial_voices.is_empty() and _global_voices.is_empty()):
		return false
	var cue_stream := profile.stream_for(cue_id)
	if cue_stream == null:
		return false
	# Offscreen actors must not consume the shared alert window before nearby ones.
	if spatial and not _spatial_voices.is_empty():
		var camera := get_viewport().get_camera_2d()
		if camera != null and _spatial_voices[0].global_position.distance_to(camera.get_screen_center_position()) >= max_distance:
			return false
	if not claim_cue_window(cue_id, Time.get_ticks_msec() / 1000.0):
		return false
	if spatial:
		var spatial_index := _voice_index_for(cue_id, _spatial_voice_cues)
		var spatial_voice := _spatial_voices[spatial_index]
		_spatial_voice_cues[spatial_index] = cue_id
		_configure_spatial_voice(spatial_voice, cue_stream, cue_id)
		_schedule_stop(spatial_voice, cue_id)
	else:
		var global_index := _voice_index_for(cue_id, _global_voice_cues)
		var global_voice := _global_voices[global_index]
		_global_voice_cues[global_index] = cue_id
		_configure_global_voice(global_voice, cue_stream, cue_id)
		_schedule_stop(global_voice, cue_id)
	cue_played.emit(cue_id)
	return true


func claim_cue_window(cue_id: StringName, now_seconds: float) -> bool:
	if cue_id not in profile.coalesced_cue_ids or profile.coalesce_seconds <= 0.0:
		return true
	# Viewport-local presentation cache, not gameplay state or an autoload.
	var scope := get_viewport()
	var recent: Dictionary = scope.get_meta(&"gameplay_audio_cue_times", {})
	var key := str(profile.get_instance_id()) + ":" + String(cue_id)
	if recent.has(key) and now_seconds - float(recent[key]) < profile.coalesce_seconds:
		return false
	recent[key] = now_seconds
	scope.set_meta(&"gameplay_audio_cue_times", recent)
	return true


func _voice_index_for(cue_id: StringName, assigned_cues: Array[StringName]) -> int:
	if profile.should_retrigger(cue_id):
		var active_index := assigned_cues.find(cue_id)
		if active_index >= 0:
			return active_index
	var selected_index := _next_voice
	_next_voice = (_next_voice + 1) % assigned_cues.size()
	return selected_index


func _configure_spatial_voice(voice: AudioStreamPlayer2D, cue_stream: AudioStream, cue_id: StringName) -> void:
	voice.stop()
	voice.stream = cue_stream
	voice.volume_db = profile.volume_db + float(profile.cue_volume_offsets_db.get(cue_id, 0.0))
	voice.pitch_scale = profile.pitch_scale
	voice.play()


func _configure_global_voice(voice: AudioStreamPlayer, cue_stream: AudioStream, cue_id: StringName) -> void:
	voice.stop()
	voice.stream = cue_stream
	voice.volume_db = profile.volume_db + float(profile.cue_volume_offsets_db.get(cue_id, 0.0))
	voice.pitch_scale = profile.pitch_scale
	voice.play()


func _schedule_stop(voice: Node, cue_id: StringName) -> void:
	var duration := profile.max_duration_for(cue_id)
	if duration <= 0.0:
		return
	var voice_id := voice.get_instance_id()
	var token := int(_playback_tokens.get(voice_id, 0)) + 1
	_playback_tokens[voice_id] = token
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if is_instance_valid(voice) and int(_playback_tokens.get(voice_id, 0)) == token:
			voice.call("stop")
	)
