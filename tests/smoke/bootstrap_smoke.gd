extends SceneTree

const MAIN_SCENE := "res://levels/vertical_slice.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed_scene := load(MAIN_SCENE) as PackedScene
	if packed_scene == null:
		push_error("Smoke failed: could not load %s" % MAIN_SCENE)
		quit(1)
		return

	var preview := packed_scene.instantiate() as LevelBuilder
	root.add_child(preview)
	await process_frame

	if preview.last_validation == null or not preview.last_validation.is_valid():
		push_error("Smoke failed: generated LevelSpec did not validate")
		preview.queue_free()
		quit(1)
		return
	if preview.get_node_or_null("Generated/Player") == null:
		push_error("Smoke failed: generated player is missing")
		preview.queue_free()
		quit(1)
		return
	if preview.get_node_or_null("Generated/Platforms/ground_intro") == null:
		push_error("Smoke failed: generated required path is missing")
		preview.queue_free()
		quit(1)
		return
	if preview.get_node_or_null("Generated/Encounters/enemy_checkpoint_commander") == null:
		push_error("Smoke failed: data-driven encounter is missing")
		preview.queue_free()
		quit(1)
		return
	if preview.get_node_or_null("Generated/Checkpoints/checkpoint_before_commander") == null:
		push_error("Smoke failed: checkpoint is missing")
		preview.queue_free()
		quit(1)
		return
	if preview.get_node_or_null("Generated/RunTelemetry") == null or preview.get_node_or_null("Generated/Hud") == null:
		push_error("Smoke failed: generated telemetry or HUD is missing")
		preview.queue_free()
		quit(1)
		return

	if preview.get_node_or_null("Generated/Flow") == null or preview.get_node_or_null("Generated/FeedbackAudio") == null:
		push_error("Smoke failed: Phase 5 flow or feedback audio is missing")
		preview.queue_free()
		quit(1)
		return

	print("SMOKE PASS: validated hardened MVP vertical slice loaded")
	paused = false
	preview.queue_free()
	await process_frame
	quit(0)
