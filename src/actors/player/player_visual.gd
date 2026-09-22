class_name PlayerVisual
extends Node2D

@export var body_radius: float = 23.0
@export var body_color: Color = Color("f4b942")
@export var outline_color: Color = Color("171b2b")
@export var visual_definition: BallVisualDefinition

var _ball_visual: BallVisual
var _override_remaining: float = 0.0


func _process(delta: float) -> void:
	_override_remaining = maxf(_override_remaining - delta, 0.0)


func _ready() -> void:
	if visual_definition != null:
		_ball_visual = BallVisual.new()
		_ball_visual.name = "BallVisual"
		_ball_visual.definition = visual_definition
		add_child(_ball_visual)
	queue_redraw()


func _draw() -> void:
	if _ball_visual != null:
		return
	draw_circle(Vector2.ZERO, body_radius + 3.0, outline_color)
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_circle(Vector2(8.0, -6.0), 4.0, Color.WHITE)
	draw_circle(Vector2(9.5, -6.0), 2.0, outline_color)
	draw_line(Vector2(7.0, 8.0), Vector2(17.0, 5.0), outline_color, 2.5, true)
	draw_line(Vector2(-15.0, -15.0), Vector2(8.0, -22.0), outline_color, 4.0, true)


func update_motion(horizontal_velocity: float, _vertical_velocity: float, airborne: bool, facing_direction: float) -> void:
	var target_rotation: float = clampf(horizontal_velocity / 1800.0, -0.12, 0.12)
	rotation = lerpf(rotation, target_rotation, 0.2)
	if _ball_visual != null:
		_ball_visual.set_facing(facing_direction)
		if _override_remaining > 0.0:
			return
		if airborne:
			_ball_visual.set_state(&"jump")
		else:
			_ball_visual.set_state(&"move" if absf(horizontal_velocity) > 5.0 else &"idle")


func play_action() -> void:
	_play_override(&"action", 0.28)


func set_weapon_art(texture: Texture2D, art_scale: float = 1.0) -> void:
	if _ball_visual != null:
		_ball_visual.set_action_equipment(texture, true, art_scale)


func play_hurt() -> void:
	_play_override(&"hurt", 0.36)


func _play_override(state_id: StringName, duration: float) -> void:
	if _ball_visual == null:
		return
	_override_remaining = duration
	_ball_visual.set_state(state_id)
