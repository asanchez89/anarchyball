extends GdUnitTestSuite


func test_closed_barrier_art_covers_extended_collider_and_opens_with_it() -> void:
	var gate := auto_free(AccessGate.new()) as AccessGate
	gate.size = Vector2(42, 144)
	gate.barrier_height = 721.0
	add_child(gate)
	var top := INF
	var bottom := -INF
	for node: Node in gate._barrier_art.get_children():
		var sprite := node as Sprite2D
		assert_object(sprite.texture).is_same(AccessGate.GATE_CLOSED_TEXTURE)
		assert_vector(sprite.scale).is_equal(Vector2(3, 3))
		top = minf(top, sprite.position.y)
		bottom = maxf(bottom, sprite.position.y + sprite.region_rect.size.y * sprite.scale.y)
	assert_float(top).is_equal(gate.size.y * 0.5 - gate.barrier_height)
	assert_bool(is_equal_approx(bottom, -gate.size.y * 0.5)).is_true()
	assert_bool(gate._barrier_art.visible).is_true()
	gate._process(0.2)
	assert_float(gate._barrier_art.modulate.a).is_between(0.43, 0.67)
	assert_bool(gate.open_for_resolution()).is_true()
	await get_tree().process_frame
	assert_bool(gate._barrier_art.visible).is_false()
	assert_bool(gate.is_collision_enabled()).is_false()
	gate.restore_open(false)
	await get_tree().process_frame
	assert_bool(gate._barrier_art.visible).is_true()
	assert_bool(gate.is_collision_enabled()).is_true()
