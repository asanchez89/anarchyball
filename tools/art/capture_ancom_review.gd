extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1000, 920)
	var stage := Node2D.new()
	root.add_child(stage)
	var definition := load("res://assets/art/actors/balls/world_0/runtime/ancom_ball_visual.tres") as BallVisualDefinition
	var states: Array[StringName] = [&"idle", &"move", &"jump", &"action", &"hurt", &"threatening", &"surrendering", &"neutralized"]
	for row: int in 8:
		for frame: int in 8:
			var ball := BallVisual.new()
			ball.definition = definition
			ball.position = Vector2(65 + frame * 120, 86 + row * 112)
			stage.add_child(ball)
			ball.set_process(false)
			ball.set_state(states[row])
			ball.set_facing(-1)
			ball._elapsed = float(frame) / definition.fps_for(states[row])
			ball._update_frame()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/ancom_v2_review.png")
	quit()
