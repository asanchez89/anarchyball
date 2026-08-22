extends SceneTree

const BOOTSTRAP_SCENE := "res://src/core/bootstrap.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed_scene := load(BOOTSTRAP_SCENE) as PackedScene
	if packed_scene == null:
		push_error("Smoke failed: could not load %s" % BOOTSTRAP_SCENE)
		quit(1)
		return

	var bootstrap := packed_scene.instantiate()
	root.add_child(bootstrap)
	await process_frame

	if bootstrap.get_node_or_null("Content/InputDiagnostics") == null:
		push_error("Smoke failed: input diagnostics are missing from bootstrap")
		bootstrap.queue_free()
		quit(1)
		return

	print("SMOKE PASS: bootstrap loaded with input diagnostics")
	bootstrap.queue_free()
	quit(0)
