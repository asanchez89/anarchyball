class_name TheftBurst
extends Node2D

@export var duration: float = 0.42
@export var radius: float = 52.0
@export var pixel_size: float = 3.0
@export var tint: Color = Color("65ffd5")
var elapsed: float = 0.0
var destination := Vector2.ZERO


func configure(origin: Vector2, recipient: Vector2) -> void:
	top_level = true
	global_position = origin
	destination = recipient - origin
	z_index = 30


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	# Stepped square pixels, never smooth circles: two brief expanding ripples.
	for ring: int in 2:
		var phase := clampf(progress * 1.35 - ring * 0.25, 0.0, 1.0)
		if phase <= 0.0 or phase >= 1.0:
			continue
		var color := tint
		color.a = 1.0 - phase
		for dot: int in 32:
			var point := Vector2.from_angle(TAU * dot / 32.0) * lerpf(18.0, radius, phase)
			draw_rect(Rect2(point.snapped(Vector2.ONE * pixel_size), Vector2.ONE * pixel_size), color)
	for spark: int in 7:
		var start := Vector2.from_angle(TAU * spark / 7.0) * 25.0
		var point := start.lerp(destination, progress)
		point.y -= sin(progress * PI) * 22.0
		var color := Color("fff3a0")
		color.a = 1.0 - progress
		draw_rect(Rect2(point.snapped(Vector2.ONE * pixel_size), Vector2.ONE * pixel_size * 2.0), color)
