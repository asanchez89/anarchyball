class_name SandboxProbeLauncher
extends Node2D

signal probe_fired()

@export var probe_scene: PackedScene
@export_range(0.05, 2.0, 0.01) var fire_cooldown: float = 0.18
@export_range(0.0, 100.0, 1.0) var muzzle_distance: float = 34.0

var _cooldown_remaining: float = 0.0
var _last_aim_direction: Vector2 = Vector2.RIGHT
var cooldown_multiplier: float = 1.0
var effect_amount_multiplier: float = 1.0
var input_enabled: bool = true


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
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
	if InputActions.is_attack_primary_pressed() and is_zero_approx(_cooldown_remaining):
		_fire_probe()


func aim_direction() -> Vector2:
	return _last_aim_direction


func _fire_probe() -> void:
	if probe_scene == null:
		return
	var probe := probe_scene.instantiate() as AimProbe
	if probe == null:
		return
	get_tree().current_scene.add_child(probe)
	probe.global_position = global_position + _last_aim_direction * muzzle_distance
	var source_identity := get_parent().get_node_or_null("Identity") as CombatIdentityComponent
	var context := EffectContext.offensive(
		EffectContext.EffectType.KINETIC_DAMAGE,
		EffectContext.Origin.PROJECTILE,
		&"training_duel"
	)
	probe.effect_amount *= effect_amount_multiplier
	probe.configure(_last_aim_direction, source_identity, context)
	_cooldown_remaining = fire_cooldown * cooldown_multiplier
	probe_fired.emit()
