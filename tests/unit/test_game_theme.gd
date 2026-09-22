extends GdUnitTestSuite

const GAME_THEME := preload("res://assets/ui/game_theme.tres")


func test_shared_theme_has_readable_font_and_distinct_focus() -> void:
	assert_object(GAME_THEME.default_font).is_not_null()
	assert_int(GAME_THEME.default_font_size).is_greater_equal(14)
	var focus := GAME_THEME.get_stylebox("focus", "Button") as StyleBoxFlat
	var normal := GAME_THEME.get_stylebox("normal", "Button") as StyleBoxFlat
	assert_bool(focus.draw_center).is_false()
	assert_int(focus.border_width_left).is_greater(normal.border_width_left)
	for action: String in ["ui_up", "ui_down", "ui_accept", "ui_cancel"]:
		var keyboard := false
		var gamepad := false
		for event: InputEvent in InputMap.action_get_events(action):
			keyboard = keyboard or event is InputEventKey
			gamepad = gamepad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		assert_bool(keyboard).is_true()
		assert_bool(gamepad).is_true()


func test_campaign_uses_single_portrait_and_restores_keyboard_focus() -> void:
	var menu := auto_free(load("res://levels/campaign/campaign_shell.tscn").instantiate()) as CampaignFlowController
	add_child(menu)
	var portrait := menu.find_child("HeroPortrait", true, false) as TextureRect
	assert_vector((portrait.texture as AtlasTexture).region.size).is_equal(Vector2(96, 96))
	assert_object(menu._first_button.get_theme_font("font")).is_same(GAME_THEME.default_font)
	menu._first_button.release_focus()
	menu._show_menu()
	assert_bool(menu._first_button.has_focus()).is_true()
	assert_object(menu._first_button.find_next_valid_focus()).is_not_null()
