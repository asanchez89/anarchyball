class_name MovementDebugHud
extends CanvasLayer

@export var player_path: NodePath

@onready var metrics_label: Label = %MetricsLabel
@onready var controls_label: Label = %ControlsLabel

var _player: PlayerController


func _ready() -> void:
	_player = get_node(player_path) as PlayerController
	controls_label.text = (
		"TECLADO  A/D o ←/→ · Espacio salto · IJKL apunta · Click dispara · Q sacude cámara\n"
		+ "GAMEPAD  Stick izq. · A salto · Stick der. apunta · RT dispara · LB sacude cámara\n"
		+ "Fase 2: dispara a cada sujeto y observa ESTADO · RAZÓN · PERMISO. Tres impactos agotan Resolve."
	)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var profile := _player.movement_profile
	metrics_label.text = (
		"FASE 2 · ETHICAL COMBAT LAB\n"
		+ "Estado: %s   Suelo: %s\n" % [_player.get_locomotion_state_name(), _player.is_on_floor()]
		+ "Posición: %7.1f, %7.1f   Velocidad: %7.1f, %7.1f\n" % [
			_player.global_position.x, _player.global_position.y, _player.velocity.x, _player.velocity.y
		]
		+ "Coyote: %4.0f ms   Buffer: %4.0f ms\n" % [
			_player.get_coyote_remaining() * 1000.0,
			_player.get_jump_buffer_remaining() * 1000.0,
		]
		+ "Altura teórica: %.1f px   Alcance seguro: %.1f px\n" % [
			MovementMath.maximum_jump_height(profile),
			MovementMath.conservative_horizontal_reach(profile),
		]
		+ "Health: %.0f/%.0f" % [
			(_player.get_node("Health") as HealthComponent).current_health,
			(_player.get_node("Health") as HealthComponent).maximum_health,
		]
	)
