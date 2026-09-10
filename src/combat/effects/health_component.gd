class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal depleted()

@export_range(1.0, 10000.0, 1.0) var maximum_health: float = 100.0
@export_range(0.0, 5.0, 0.01) var invulnerability_duration: float = 0.20

var current_health: float
var _invulnerability_remaining: float = 0.0


func _ready() -> void:
	reset()


func _physics_process(delta: float) -> void:
	_invulnerability_remaining = maxf(_invulnerability_remaining - delta, 0.0)


func damage(amount: float) -> bool:
	if amount <= 0.0 or _invulnerability_remaining > 0.0 or current_health <= 0.0:
		return false
	current_health = maxf(current_health - amount, 0.0)
	_invulnerability_remaining = invulnerability_duration
	health_changed.emit(current_health, maximum_health)
	if is_zero_approx(current_health):
		depleted.emit()
	return true


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	current_health = minf(current_health + amount, maximum_health)
	health_changed.emit(current_health, maximum_health)


func reset() -> void:
	current_health = maximum_health
	_invulnerability_remaining = 0.0
	health_changed.emit(current_health, maximum_health)


func restore(value: float) -> void:
	current_health = clampf(value, 1.0, maximum_health)
	_invulnerability_remaining = 0.0
	health_changed.emit(current_health, maximum_health)
