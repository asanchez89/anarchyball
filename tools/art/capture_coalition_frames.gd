extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1000, 720)
	RenderingServer.set_default_clear_color(Color("172333"))
	var visuals: Array[BallVisual] = []
	for kind: int in 2:
		var id := "black_anarchy" if kind == 0 else "left_libertarian"
		var definition := load("res://assets/art/actors/balls/world_0/runtime/" + id + "_ball_visual.tres") as BallVisualDefinition
		for row: int in 4:
			var state: StringName = [&"idle", &"move", &"action", &"surrendering"][row]
			var label := Label.new()
			label.text = id + " / " + String(state)
			label.position = Vector2(kind * 500 + 15, row * 170 + 8)
			root.add_child(label)
			for frame: int in 4:
				var visual := BallVisual.new()
				visual.definition = definition
				visual.position = Vector2(kind * 500 + 65 + frame * 120, row * 170 + 120)
				root.add_child(visual)
				visual.set_process(false)
				visual.set_state(state)
				visual._elapsed = (float(frame) + 0.01) / definition.fps_for(state)
				visual._update_frame()
				visuals.append(visual)
				var line := Line2D.new()
				line.add_point(Vector2(visual.position.x - 48, visual.position.y + definition.body_ground_y))
				line.add_point(Vector2(visual.position.x + 48, visual.position.y + definition.body_ground_y))
				line.width = 1.0
				line.default_color = Color.CYAN
				root.add_child(line)
	DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
	for direction: int in [-1, 1]:
		for visual: BallVisual in visuals:
			visual.set_facing(direction)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/workshop_review/coalition_frames_%d.png" % direction)
	quit()
