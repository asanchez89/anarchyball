class_name ContractorDefensiveResponse
extends Node

signal state_changed(active: bool, remaining: float)

@export var profile: DefensiveResponseProfile

var remaining: float = 0.0
var _launcher: SandboxProbeLauncher


func _ready() -> void:
	_launcher = get_parent().get_node_or_null("ProbeLauncher") as SandboxProbeLauncher
	assert(profile != null and profile.is_valid(), "DefensiveResponseProfile inválido")


func _process(delta: float) -> void:
	if remaining <= 0.0:
		return
	remaining = maxf(remaining - delta, 0.0)
	if is_zero_approx(remaining):
		_apply_launcher_modifiers(false)
	state_changed.emit(is_active(), remaining)


func activate(_reason: ConflictStateComponent.AggressorReason) -> void:
	remaining = profile.duration
	_apply_launcher_modifiers(true)
	state_changed.emit(true, remaining)


func is_active() -> bool:
	return remaining > 0.0


func normalized_remaining() -> float:
	return remaining / profile.duration if profile != null and profile.duration > 0.0 else 0.0


func reset() -> void:
	remaining = 0.0
	_apply_launcher_modifiers(false)
	state_changed.emit(false, 0.0)


func _apply_launcher_modifiers(active: bool) -> void:
	if _launcher == null:
		return
	_launcher.cooldown_multiplier = profile.fire_cooldown_multiplier if active else 1.0
	_launcher.effect_amount_multiplier = profile.effect_amount_multiplier if active else 1.0
