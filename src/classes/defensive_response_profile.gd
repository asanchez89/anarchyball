class_name DefensiveResponseProfile
extends Resource

@export_range(0.1, 30.0, 0.1) var duration: float = 5.0
@export_range(0.1, 1.0, 0.05) var fire_cooldown_multiplier: float = 0.55
@export_range(1.0, 3.0, 0.05) var effect_amount_multiplier: float = 1.35


func is_valid() -> bool:
	return duration > 0.0 and fire_cooldown_multiplier > 0.0 and effect_amount_multiplier >= 1.0
