class_name PixelBallPrototype
extends Node2D

enum Variant {
	COMPACT_24_X_32,
	DETAIL_32_X_32,
}

enum VisualState {
	IDLE,
	MOVE,
	JUMP,
	FIRE,
	THREATENING,
	SURRENDERING,
}

const ART_SCALE: float = 3.0
const OUTLINE := Color("140d24")
const BODY_DARK := Color("17131d")
const BODY_LIGHT := Color("32283d")
const IDEOLOGY_YELLOW := Color("ffe21a")
const MAGENTA := Color("df49bd")
const CYAN := Color("57d7dd")
const EYE := Color("fff4ec")

@export var variant: Variant = Variant.COMPACT_24_X_32
@export var visual_state: VisualState = VisualState.IDLE
@export var facing_direction: float = 1.0

var _elapsed: float = 0.0
var _aim_direction := Vector2.RIGHT


func _ready() -> void:
	scale = Vector2(ART_SCALE, ART_SCALE)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func set_visual_state(value: VisualState) -> void:
	visual_state = value
	_elapsed = 0.0
	queue_redraw()


func set_facing(value: float) -> void:
	if is_zero_approx(value):
		return
	facing_direction = signf(value)
	queue_redraw()


func set_aim(value: Vector2) -> void:
	if value.length_squared() <= 0.04:
		return
	_aim_direction = value.normalized()
	queue_redraw()


func source_canvas() -> Vector2i:
	return Vector2i(24, 32) if variant == Variant.COMPACT_24_X_32 else Vector2i(32, 32)


func _draw() -> void:
	var canvas := source_canvas()
	var center := Vector2i(canvas.x / 2, 19)
	var radius := 8 if variant == Variant.COMPACT_24_X_32 else 9
	center += _state_offset()
	_draw_shadow(center, radius)
	_draw_body(center, radius)
	_draw_highlight(center, radius)
	_draw_ideology_surface(center, radius)
	_draw_eyes(center, radius)
	_draw_pennant(center, radius)
	_draw_emitter(center, radius)
	_draw_state_marker(center, radius)


func _state_offset() -> Vector2i:
	match visual_state:
		VisualState.IDLE:
			return Vector2i(0, -1 if int(_elapsed * 3.0) % 2 == 0 else 0)
		VisualState.MOVE:
			return Vector2i(0, -1 if int(_elapsed * 8.0) % 2 == 0 else 0)
		VisualState.JUMP:
			return Vector2i(0, -3)
		VisualState.FIRE:
			return Vector2i(-int(signf(facing_direction)), 0)
		_:
			return Vector2i.ZERO


func _draw_shadow(center: Vector2i, radius: int) -> void:
	var width := radius + 2
	for x: int in range(-width, width + 1):
		if abs(x) <= width - 2 or x % 2 == 0:
			_pixel(center + Vector2i(x, radius + 3), Color("0b071280"))


func _draw_body(center: Vector2i, radius: int) -> void:
	var outer_squared := radius * radius
	var inner_squared := (radius - 2) * (radius - 2)
	for y: int in range(-radius, radius + 1):
		for x: int in range(-radius, radius + 1):
			var distance_squared := x * x + y * y
			if distance_squared > outer_squared:
				continue
			var color := OUTLINE if distance_squared > inner_squared else BODY_DARK
			if color == BODY_DARK and y > 2 and x * facing_direction < 2.0:
				color = BODY_LIGHT
			_pixel(center + Vector2i(x, y), color)


func _draw_highlight(center: Vector2i, radius: int) -> void:
	var side := -1 if facing_direction > 0.0 else 1
	_pixel(center + Vector2i(side * (radius - 3), -radius + 3), MAGENTA)
	_pixel(center + Vector2i(side * (radius - 2), -radius + 4), MAGENTA)
	if variant == Variant.DETAIL_32_X_32:
		_pixel(center + Vector2i(side * (radius - 4), -radius + 3), Color("f16bcf"))


func _draw_ideology_surface(center: Vector2i, radius: int) -> void:
	# Polcompball aporta la identidad interior; el acabado y volumen siguen la biblia del juego.
	for y: int in range(-radius + 2, radius - 1):
		for x: int in range(-radius + 2, radius - 1):
			if x * x + y * y > (radius - 2) * (radius - 2):
				continue
			if x + y < -1:
				_pixel(center + Vector2i(x, y), IDEOLOGY_YELLOW)


func _draw_eyes(center: Vector2i, radius: int) -> void:
	var side := 1 if facing_direction > 0.0 else -1
	var eye_x := center.x + side * (radius - 4)
	var blink := visual_state == VisualState.SURRENDERING or (
		visual_state == VisualState.IDLE and int(_elapsed * 2.0) % 9 == 8
	)
	if blink:
		_pixel(Vector2i(eye_x - side, center.y - 2), EYE)
		_pixel(Vector2i(eye_x, center.y - 2), EYE)
		_pixel(Vector2i(eye_x + side, center.y - 2), EYE)
		return
	var angry := visual_state == VisualState.THREATENING or visual_state == VisualState.FIRE
	for y: int in range(-3, 1):
		for column: int in range(0, 2):
			var x := eye_x + side * (column * 3 - 1)
			if not angry or y >= -2 + column:
				_pixel(Vector2i(x, center.y + y), EYE)
				_pixel(Vector2i(x + side, center.y + y), EYE)


func _draw_pennant(center: Vector2i, radius: int) -> void:
	var pole_x := center.x - int(signf(facing_direction)) * 3
	var color := EYE if visual_state == VisualState.SURRENDERING else OUTLINE
	for y: int in range(center.y - radius - 6, center.y - radius + 1):
		_pixel(Vector2i(pole_x, y), color)
	var flag_top := center.y - radius - 6
	for row: int in range(0, 4):
		for column: int in range(0, 5 - row):
			_pixel(Vector2i(pole_x + int(signf(facing_direction)) * (column + 1), flag_top + row), color)
	if visual_state != VisualState.SURRENDERING:
		_pixel(Vector2i(pole_x + int(signf(facing_direction)) * 2, flag_top + 1), IDEOLOGY_YELLOW)


func _draw_emitter(center: Vector2i, radius: int) -> void:
	var side := 1 if facing_direction > 0.0 else -1
	var origin := center + Vector2i(side * (radius + 1), 1)
	for y: int in range(-2, 3):
		for x: int in range(-1, 2):
			_pixel(origin + Vector2i(side * x, y), OUTLINE)
	_pixel(origin, CYAN)
	_pixel(origin + Vector2i(0, -1), MAGENTA)
	if visual_state != VisualState.FIRE:
		return
	var direction := _aim_direction
	if direction.x * facing_direction < 0.15:
		direction.x = 0.15 * facing_direction
	if direction.is_zero_approx():
		direction = Vector2(facing_direction, 0.0)
	direction = direction.normalized()
	for step: int in range(2, 7):
		var point := Vector2(origin) + direction * float(step)
		_pixel(Vector2i(roundi(point.x), roundi(point.y)), CYAN if step % 2 == 0 else MAGENTA)


func _draw_state_marker(center: Vector2i, radius: int) -> void:
	if visual_state != VisualState.THREATENING:
		return
	var marker_x := center.x + radius + 4
	for y: int in range(center.y - radius, center.y - radius + 4):
		_pixel(Vector2i(marker_x, y), EYE)
	_pixel(Vector2i(marker_x, center.y - radius + 6), EYE)


func _pixel(position: Vector2i, color: Color) -> void:
	draw_rect(Rect2(Vector2(position), Vector2.ONE), color)
