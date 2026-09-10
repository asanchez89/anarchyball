class_name ResolveComponent
extends Node

signal resolve_changed(current: float, maximum: float)
signal surrender_threshold_reached()

@export_range(1.0, 10000.0, 1.0) var maximum_resolve: float = 100.0
@export_range(0.0, 10000.0, 1.0) var surrender_threshold: float = 0.0

var current_resolve: float
var _threshold_emitted: bool = false


func _ready() -> void:
	reset()


func reduce(amount: float) -> void:
	if amount <= 0.0 or _threshold_emitted:
		return
	current_resolve = maxf(current_resolve - amount, surrender_threshold)
	resolve_changed.emit(current_resolve, maximum_resolve)
	if current_resolve <= surrender_threshold:
		_threshold_emitted = true
		surrender_threshold_reached.emit()


func reset() -> void:
	current_resolve = maximum_resolve
	_threshold_emitted = false
	resolve_changed.emit(current_resolve, maximum_resolve)


func restore(value: float) -> void:
	current_resolve = clampf(value, surrender_threshold, maximum_resolve)
	_threshold_emitted = current_resolve <= surrender_threshold
	resolve_changed.emit(current_resolve, maximum_resolve)
