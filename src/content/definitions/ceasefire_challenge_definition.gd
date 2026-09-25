class_name CeasefireChallengeDefinition
extends Resource

enum AttackMode { ROTATING_FIRE, CONTACT_RAID, AUTONOMOUS_FLANK, MARKED_PULSE, MIXED_STAGES }

@export var mode: AttackMode = AttackMode.ROTATING_FIRE
@export var title: String = "ALTO EL FUEGO"
@export var compact_actor_hud: bool = false
@export var duration: float = 35.0
@export var warning_seconds: float = 1.2
@export var turn_interval: float = 1.4
@export var activation_range: float = 650.0
@export var zone_padding: float = 350.0
@export_range(0.0, 0.4, 0.01) var ceasefire_core_fraction: float = 0.0
@export var any_surrender_resolves: bool = true
@export var collective_commitment: bool = false
@export var tactical_retreat: bool = false
@export var retreat_safety_gain: float = 80.0
@export var retreat_resolve_ratio: float = 0.7
@export var retreat_speed: float = 150.0
@export var pursuit_radius: float = 420.0
@export var return_speed: float = 130.0
@export var home_tolerance: float = 10.0
@export var jump_speed: float = 640.0
@export var jump_gravity: float = 1600.0
@export var jump_horizontal_speed: float = 240.0
@export var jump_cooldown: float = 0.4
@export var chase_speed: float = 190.0
@export var commitment_range: float = 220.0
@export var contact_radius: float = 52.0
@export var contact_damage: float = 4.0
@export var contact_cooldown: float = 2.0
@export var theft_effect: PackedScene = preload("res://src/presentation/theft_burst.tscn")
@export var personal_space: float = 70.0
@export_range(0, 2, 1) var retreat_cover_count: int = 2
@export var retreat_cover_radius: float = 700.0
@export var retreat_cover_cooldown: float = 2.5
@export var flank_distance: float = 160.0
@export var encirclement_hold: float = 0.6
@export var encirclement_cooldown: float = 5.0
@export var encirclement_bonus: float = 2.0
@export var encirclement_bonus_cap: float = 6.0
@export_range(1, 2, 1) var simultaneous_attacks: int = 2
@export var surrender_time_bonus: float = 3.0
@export var surrender_bonus_cap: float = 9.0
@export var pulse_warning: float = 1.5
@export var pulse_radius: float = 65.0
@export var pulse_safe_lane_width: float = 120.0
@export var pulse_vfx: Texture2D = preload("res://assets/art/vfx/world_0/warped_pulse_spark.png")
@export var pulse_vfx_frames: int = 5
@export var pulse_vfx_scale: int = 2
@export var pulse_burst_seconds: float = 0.3
@export var pulse_damage: float = 3.0
@export var pulse_push: float = 100.0
@export var pulse_interval: float = 3.0
@export var clean_dodge_bonus: float = 1.0
@export var clean_dodge_cap: float = 8.0
@export var group_profiles: Array[Resource] = []
@export var group_sizes := PackedInt32Array()
@export var stage_delays := PackedFloat32Array()
@export var stolen_items: Dictionary = {"light_ammo": 8, "trade_parts": 2}
@export var theft_limit: Dictionary = {"light_ammo": 24, "trade_parts": 6}
@export var reward_sats: int = 20
@export var no_attack_bonus: int = 20
@export var no_hit_bonus: int = 20


func is_valid() -> bool:
	if pulse_vfx_frames <= 0 or pulse_vfx_scale <= 0 or not is_finite(pulse_burst_seconds) or pulse_burst_seconds <= 0.0:
		return false
	if pulse_vfx == null or pulse_vfx.get_width() % pulse_vfx_frames != 0:
		return false
	for value: float in [encirclement_hold, encirclement_cooldown]:
		if not is_finite(value) or value <= 0.0:
			return false
	for value: float in [encirclement_bonus, encirclement_bonus_cap]:
		if not is_finite(value) or value < 0.0:
			return false
	if retreat_cover_count < 0 or retreat_cover_count > 2 or not is_finite(retreat_cover_radius) or retreat_cover_radius <= 0.0 or not is_finite(retreat_cover_cooldown) or retreat_cover_cooldown < 0.0:
		return false
	if mode == AttackMode.MIXED_STAGES:
		if group_profiles.is_empty() or group_profiles.size() != group_sizes.size() or group_sizes.size() != stage_delays.size():
			return false
		for i: int in group_profiles.size():
			if not group_profiles[i] is CeasefireChallengeDefinition or group_profiles[i].mode == AttackMode.MIXED_STAGES or not group_profiles[i].is_valid() or group_sizes[i] <= 0 or not is_finite(stage_delays[i]) or stage_delays[i] < 0.0 or (i > 0 and stage_delays[i] < stage_delays[i - 1]):
				return false
	for value: float in [pulse_warning, pulse_radius, pulse_interval, pulse_safe_lane_width]:
		if not is_finite(value) or value <= 0.0:
			return false
	for value: float in [pulse_damage, pulse_push, clean_dodge_bonus, clean_dodge_cap]:
		if not is_finite(value) or value < 0.0:
			return false
	if simultaneous_attacks < 1 or simultaneous_attacks > 2 or not is_finite(flank_distance) or flank_distance <= 0.0:
		return false
	if not is_finite(surrender_time_bonus) or not is_finite(surrender_bonus_cap) or surrender_time_bonus < 0.0 or surrender_bonus_cap < 0.0:
		return false
	if not is_finite(ceasefire_core_fraction) or ceasefire_core_fraction < 0.0 or ceasefire_core_fraction > 0.4:
		return false
	for value: float in [retreat_safety_gain, retreat_speed, pursuit_radius, return_speed, home_tolerance, jump_speed, jump_gravity, jump_horizontal_speed, jump_cooldown]:
		if not is_finite(value) or value <= 0.0:
			return false
	if not is_finite(retreat_resolve_ratio) or retreat_resolve_ratio <= 0.0 or retreat_resolve_ratio >= 1.0:
		return false
	if duration <= 0.0 or warning_seconds <= 0.0 or turn_interval <= 0.0 or activation_range <= 0.0 or zone_padding <= 0.0 or chase_speed <= 0.0 or commitment_range <= 0.0 or contact_radius <= 0.0 or contact_cooldown <= 0.0 or contact_damage < 0.0:
		return false
	if reward_sats < 0 or no_attack_bonus < 0 or no_hit_bonus < 0 or personal_space <= 0.0:
		return false
	for item: String in stolen_items:
		if int(stolen_items[item]) <= 0 or int(theft_limit.get(item, 0)) < int(stolen_items[item]):
			return false
	return true
