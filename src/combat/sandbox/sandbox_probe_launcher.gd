class_name SandboxProbeLauncher
extends Node2D

signal probe_fired()
signal reload_started(weapon_index: int)

@export var probe_scene: PackedScene
@export_range(0.05, 2.0, 0.01) var fire_cooldown: float = 0.18
@export_range(0.0, 100.0, 1.0) var muzzle_distance: float = 34.0

var _cooldown_remaining: float = 0.0
var _last_aim_direction: Vector2 = Vector2.RIGHT
var cooldown_multiplier: float = 1.0
var effect_amount_multiplier: float = 1.0
var input_enabled: bool = true
var last_weapon_index: int = 0
var _magazine_used: Dictionary = {}
var _reload_remaining: Dictionary = {}


func _physics_process(delta: float) -> void:
	advance_weapon_timers(delta)
	_process_attack_input()


func advance_weapon_timers(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	for index: int in _reload_remaining.keys():
		_reload_remaining[index] = maxf(float(_reload_remaining[index]) - delta, 0.0)
		if is_zero_approx(float(_reload_remaining[index])):
			_magazine_used[index] = 0
			_reload_remaining.erase(index)


func magazine_remaining(weapon_index: int, capacity: int) -> int:
	return maxi(0, capacity - int(_magazine_used.get(weapon_index, 0)))


func reload_remaining(weapon_index: int) -> float:
	return float(_reload_remaining.get(weapon_index, 0.0))


func capture_weapon_state() -> Dictionary:
	var magazines: Dictionary = {}
	var reloads: Dictionary = {}
	for index: int in _magazine_used:
		magazines[str(index)] = _magazine_used[index]
	for index: int in _reload_remaining:
		reloads[str(index)] = _reload_remaining[index]
	return {"magazines": magazines, "reloads": reloads, "cooldown": _cooldown_remaining}


func restore_weapon_state(state: Dictionary) -> void:
	_magazine_used.clear()
	_reload_remaining.clear()
	_cooldown_remaining = maxf(0.0, float(state.get("cooldown", 0.0)))
	for key: String in state.get("magazines", {}):
		_magazine_used[int(key)] = maxi(0, int(state.magazines[key]))
	for key: String in state.get("reloads", {}):
		var remaining := maxf(0.0, float(state.reloads[key]))
		if remaining > 0.0:
			_reload_remaining[int(key)] = remaining
		else:
			_magazine_used[int(key)] = 0


func _process_attack_input() -> void:
	if not input_enabled:
		return
	var player := get_parent() as PlayerController
	var facing: float = player.facing_direction if player != null else 1.0
	var directional_aim: Vector2 = InputActions.directional_aim_vector()
	if directional_aim.length_squared() > 0.04:
		_last_aim_direction = LaunchDirectionResolver.resolve(directional_aim, facing)
	else:
		var pointer_aim: Vector2 = get_global_mouse_position() - global_position
		if pointer_aim.length_squared() > 64.0:
			_last_aim_direction = LaunchDirectionResolver.resolve(pointer_aim, facing)
		else:
			_last_aim_direction = LaunchDirectionResolver.resolve(_last_aim_direction, facing)
	if is_zero_approx(_cooldown_remaining):
		if player != null and player.inventory != null and Input.is_action_pressed(InputActions.ATTACK_SECONDARY):
			_fire_probe(1)
		elif InputActions.is_attack_primary_pressed():
			_fire_probe(0)


func aim_direction() -> Vector2:
	return _last_aim_direction


func _fire_probe(weapon_index: int = 0) -> void:
	if probe_scene == null or reload_remaining(weapon_index) > 0.0:
		return
	var player := get_parent() as PlayerController
	var weapon: Dictionary = {}
	if player != null and player.inventory != null:
		if weapon_index < 0 or weapon_index >= player.inventory.profile.weapons.size():
			return
		weapon = player.inventory.profile.weapons[weapon_index]
		if player.inventory.count(String(weapon.ammo)) <= 0:
			_cooldown_remaining = 0.2
			return
	var probe := probe_scene.instantiate() as AimProbe
	if probe == null:
		return
	if not weapon.is_empty():
		player.inventory.spend(String(weapon.ammo), 1)
		probe.effect_amount = float(weapon.damage)
	get_parent().get_parent().add_child(probe)
	probe.global_position = global_position + _last_aim_direction * muzzle_distance
	var obstruction := ProjectileTerrain.obstruction(get_world_2d(), global_position, probe.global_position)
	if not obstruction.is_empty():
		probe.global_position = (obstruction.position as Vector2) - _last_aim_direction
	var source_identity := get_parent().get_node_or_null("Identity") as CombatIdentityComponent
	var context := EffectContext.offensive(
		EffectContext.EffectType.KINETIC_DAMAGE,
		EffectContext.Origin.PROJECTILE,
		&"training_duel"
	)
	probe.effect_amount *= effect_amount_multiplier
	probe.configure(_last_aim_direction, source_identity, context)
	if not weapon.is_empty():
		probe.missile_sprite.scale = Vector2.ONE * float(weapon.get("projectile_scale", 2.0))
	last_weapon_index = weapon_index
	_cooldown_remaining = float(weapon.get("cooldown", fire_cooldown)) * cooldown_multiplier
	probe_fired.emit()
	var capacity := int(weapon.get("magazine_size", 0))
	if capacity > 0:
		_magazine_used[weapon_index] = int(_magazine_used.get(weapon_index, 0)) + 1
		if int(_magazine_used[weapon_index]) >= capacity:
			_reload_remaining[weapon_index] = float(weapon.get("reload_seconds", 0.75))
			reload_started.emit(weapon_index)
