class_name PickupPresentationProfile
extends Resource

@export var aura_texture: Texture2D
@export var aura_diameter: float = 96.0
@export var pulse_seconds: float = 1.8
@export var pulse_minimum: float = 0.6
@export var warning_blinks_per_second: float = 2.0
@export var warning_dim_alpha: float = 0.22
@export var collection_padding: float = 6.0
@export var minimum_collection_size: float = 20.0
@export var drop_arc_seconds: float = 0.6
@export var drop_arc_height: float = 80.0
@export var drop_collection_delay: float = 0.2


func is_valid() -> bool:
	if not is_finite(drop_arc_seconds) or drop_arc_seconds <= 0.0 or not is_finite(drop_arc_height) or drop_arc_height <= 0.0 or not is_finite(drop_collection_delay) or drop_collection_delay < 0.0 or drop_collection_delay >= drop_arc_seconds:
		return false
	if not is_finite(collection_padding) or collection_padding < 0.0 or not is_finite(minimum_collection_size) or minimum_collection_size <= 0.0:
		return false
	return aura_texture != null and is_finite(aura_diameter) and aura_diameter > 0.0 and is_finite(pulse_seconds) and pulse_seconds > 0.0 and pulse_minimum > 0.0 and pulse_minimum <= 1.0 and warning_blinks_per_second > 0.0 and warning_blinks_per_second <= 2.0 and warning_dim_alpha > 0.0 and warning_dim_alpha < 1.0
