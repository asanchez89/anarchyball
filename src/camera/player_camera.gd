class_name PlayerCamera
extends Camera2D

@export_range(0.1, 20.0, 0.1) var smoothing_speed: float = 7.0
@export var shake_enabled: bool = true
@export_range(0.0, 1.0, 0.05) var shake_intensity: float = 1.0
@export_range(0.1, 50.0, 0.1) var shake_decay: float = 14.0
@export_range(0.0, 32.0, 0.5) var maximum_shake_offset: float = 8.0

var _shake_strength: float = 0.0
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = smoothing_speed
	_random.seed = 84621


func _process(delta: float) -> void:
	position_smoothing_speed = smoothing_speed
	_shake_strength = maxf(_shake_strength - shake_decay * delta, 0.0)
	if not shake_enabled or is_zero_approx(_shake_strength):
		offset = Vector2.ZERO
		return
	var amplitude: float = minf(_shake_strength * shake_intensity, maximum_shake_offset)
	offset = Vector2(
		_random.randf_range(-amplitude, amplitude),
		_random.randf_range(-amplitude, amplitude)
	)


func add_shake(strength: float) -> void:
	if shake_enabled:
		_shake_strength = minf(_shake_strength + maxf(strength, 0.0), maximum_shake_offset)
