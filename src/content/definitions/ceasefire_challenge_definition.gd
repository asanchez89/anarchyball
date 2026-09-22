class_name CeasefireChallengeDefinition
extends Resource

enum AttackMode { ROTATING_FIRE, CONTACT_RAID }

@export var mode: AttackMode = AttackMode.ROTATING_FIRE
@export var title: String = "ALTO EL FUEGO"
@export var duration: float = 35.0
@export var warning_seconds: float = 1.2
@export var turn_interval: float = 1.4
@export var activation_range: float = 650.0
@export var zone_padding: float = 350.0
@export var any_surrender_resolves: bool = true
@export var collective_commitment: bool = false
@export var tactical_relay: bool = false
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
@export var stolen_items: Dictionary = {"light_ammo": 8, "trade_parts": 2}
@export var theft_limit: Dictionary = {"light_ammo": 24, "trade_parts": 6}
@export var reward_sats: int = 20
@export var no_attack_bonus: int = 20
@export var no_hit_bonus: int = 20


func is_valid() -> bool:
	for value: float in [retreat_speed, pursuit_radius, return_speed, home_tolerance, jump_speed, jump_gravity, jump_horizontal_speed, jump_cooldown]:
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
