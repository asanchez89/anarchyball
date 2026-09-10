class_name PlayerMovementProfile
extends Resource

@export_group("Horizontal")
@export_range(1.0, 2000.0, 1.0, "or_greater") var run_speed: float = 300.0
@export_range(1.0, 10000.0, 1.0, "or_greater") var run_acceleration: float = 1800.0
@export_range(1.0, 10000.0, 1.0, "or_greater") var run_deceleration: float = 2400.0
@export_range(1.0, 10000.0, 1.0, "or_greater") var air_acceleration: float = 1200.0
@export_range(0.0, 1.0, 0.01) var air_control: float = 0.75

@export_group("Vertical")
@export_range(1.0, 10000.0, 1.0, "or_greater") var gravity: float = 1800.0
@export_range(1.0, 3000.0, 1.0, "or_greater") var jump_velocity: float = 620.0
@export_range(1.0, 5000.0, 1.0, "or_greater") var max_fall_speed: float = 900.0
@export_range(0.01, 0.5, 0.01) var coyote_time: float = 0.12
@export_range(0.01, 0.5, 0.01) var jump_buffer_time: float = 0.12
@export_range(0.05, 1.0, 0.01) var short_hop_multiplier: float = 0.45

@export_group("Reserved for Dash")
@export_range(1.0, 3000.0, 1.0, "or_greater") var dash_speed: float = 720.0
@export_range(0.01, 1.0, 0.01) var dash_duration: float = 0.14
@export_range(0.0, 5.0, 0.01) var dash_cooldown: float = 0.45


func is_valid() -> bool:
	return (
		run_speed > 0.0
		and run_acceleration > 0.0
		and run_deceleration > 0.0
		and air_acceleration > 0.0
		and air_control >= 0.0
		and air_control <= 1.0
		and gravity > 0.0
		and jump_velocity > 0.0
		and max_fall_speed > 0.0
		and coyote_time > 0.0
		and jump_buffer_time > 0.0
		and short_hop_multiplier > 0.0
		and short_hop_multiplier <= 1.0
	)
