class_name FeedbackTone
extends AudioStreamPlayer

enum Cue {
	NOTICE,
	AGGRESSION,
	CHECKPOINT,
	BOSS_PHASE,
	SUCCESS,
}

const MIX_RATE: float = 22050.0

var _playback: AudioStreamGeneratorPlayback
var _frequency: float = 440.0
var _frames_remaining: int = 0
var _phase: float = 0.0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.2
	stream = generator
	volume_db = -18.0
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if _playback == null or _frames_remaining <= 0:
		return
	var frames := mini(_playback.get_frames_available(), _frames_remaining)
	for _index: int in frames:
		var envelope := minf(float(_frames_remaining) / (MIX_RATE * 0.04), 1.0)
		var sample := sin(_phase) * 0.22 * envelope
		_playback.push_frame(Vector2(sample, sample))
		_phase = fmod(_phase + TAU * _frequency / MIX_RATE, TAU)
		_frames_remaining -= 1


func play_cue(cue: Cue) -> void:
	match cue:
		Cue.AGGRESSION:
			_frequency = 220.0
		Cue.CHECKPOINT:
			_frequency = 660.0
		Cue.BOSS_PHASE:
			_frequency = 165.0
		Cue.SUCCESS:
			_frequency = 880.0
		_:
			_frequency = 440.0
	_frames_remaining = int(MIX_RATE * (0.22 if cue == Cue.SUCCESS else 0.12))
	_phase = 0.0


func _exit_tree() -> void:
	stop()
	_playback = null
	stream = null
