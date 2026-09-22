class_name SliceFlowController
extends CanvasLayer

signal accessibility_changed(settings: AccessibilitySettings)

const PIXEL_FONT := preload("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf")

var _host: LevelBuilder
var _title: String
var _intro: String
var _completion: String
var _start_in_menu: bool = true
var _overlay: ColorRect
var _heading: Label
var _body: Label
var _primary_button: Button
var _restart_button: Button
var _profile_button: Button
var _shake_button: Button
var _subtitles_button: Button
var _scale_button: Button
var _campaign_button: Button
var _briefing_image: TextureRect
var _page_label: Label
var _accessibility_row: HBoxContainer
var _controls_label: Label
var _settings: AccessibilitySettings
var _panel: VBoxContainer
var _is_completion: bool = false
var _briefing_cards: Array[Dictionary] = []
var _briefing_index: int = -1


func configure(
	host: LevelBuilder,
	title: String,
	intro: String,
	completion: String,
	start_in_menu: bool,
	settings: AccessibilitySettings,
	briefing_cards: Array = []
) -> void:
	_host = host
	_title = title
	_intro = intro
	_completion = completion
	_start_in_menu = start_in_menu
	_settings = settings
	_briefing_cards.clear()
	for card_value: Variant in briefing_cards:
		if card_value is Dictionary:
			_briefing_cards.append((card_value as Dictionary).duplicate(true))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	if _start_in_menu:
		if _briefing_cards.is_empty():
			_show_overlay(_title, _intro, "COMENZAR")
		else:
			_briefing_index = 0
			_show_briefing_card()
		get_tree().paused = true
	else:
		_overlay.visible = false


func _process(_delta: float) -> void:
	if get_tree().get_first_node_in_group("shop_overlay") != null or get_tree().get_first_node_in_group("player_menu_overlay") != null:
		return
	if not InputActions.is_pause_just_pressed() or _is_completion:
		return
	if _overlay.visible:
		_resume()
	else:
		_show_overlay("PAUSA", "El estado del encounter se conserva.", "CONTINUAR")
		get_tree().paused = true


func show_completion() -> void:
	_is_completion = true
	_briefing_index = -1
	_show_overlay("MISIÓN COMPLETADA" if _host.campaign_mode else "SLICE COMPLETADO", _completion, "CONTINUAR" if _host.campaign_mode else "VOLVER A JUGAR")
	_restart_button.visible = false
	get_tree().paused = true


func append_completion_summary(summary: String) -> void:
	_completion = "%s\n\n%s" % [_completion, summary]


func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.theme = preload("res://assets/ui/game_theme.tres")
	_overlay.name = "MenuOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color("101527e8")
	add_child(_overlay)
	_panel = VBoxContainer.new()
	_panel.name = "BriefingPanel"
	_panel.position = Vector2(180.0, 42.0)
	_panel.size = Vector2(920.0, 636.0)
	_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_theme_constant_override("separation", 18)
	_overlay.add_child(_panel)
	_heading = Label.new()
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.add_theme_font_override("font", PIXEL_FONT)
	_heading.add_theme_font_size_override("font_size", 30)
	_panel.add_child(_heading)
	_briefing_image = TextureRect.new()
	_briefing_image.name = "BriefingImage"
	_briefing_image.custom_minimum_size = Vector2(220.0, 220.0)
	_briefing_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_briefing_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_briefing_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_panel.add_child(_briefing_image)
	_body = Label.new()
	_body.custom_minimum_size = Vector2(860.0, 112.0)
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_override("font", PIXEL_FONT)
	_body.add_theme_font_size_override("font_size", 17)
	_panel.add_child(_body)
	_page_label = Label.new()
	_page_label.name = "BriefingPage"
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_override("font", PIXEL_FONT)
	_page_label.add_theme_font_size_override("font_size", 12)
	_page_label.add_theme_color_override("font_color", Color("76e6ff"))
	_panel.add_child(_page_label)
	_primary_button = Button.new()
	_primary_button.custom_minimum_size = Vector2(280.0, 48.0)
	_primary_button.pressed.connect(_on_primary_pressed)
	_panel.add_child(_primary_button)
	_profile_button = Button.new()
	_profile_button.custom_minimum_size = Vector2(280.0, 42.0)
	_profile_button.pressed.connect(_cycle_playtest_profile)
	_panel.add_child(_profile_button)
	_restart_button = Button.new()
	_restart_button.text = "REINICIAR SLICE"
	_restart_button.custom_minimum_size = Vector2(280.0, 42.0)
	_restart_button.pressed.connect(_restart)
	_panel.add_child(_restart_button)
	_campaign_button = Button.new()
	_campaign_button.text = "VOLVER A CAMPAÑA"
	_campaign_button.custom_minimum_size = Vector2(280.0, 42.0)
	_campaign_button.visible = _host.campaign_mode
	_campaign_button.pressed.connect(_host.abandon_run)
	_panel.add_child(_campaign_button)
	_accessibility_row = HBoxContainer.new()
	_accessibility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_accessibility_row.add_theme_constant_override("separation", 8)
	_panel.add_child(_accessibility_row)
	_shake_button = Button.new()
	_shake_button.pressed.connect(_toggle_shake)
	_accessibility_row.add_child(_shake_button)
	_subtitles_button = Button.new()
	_subtitles_button.pressed.connect(_toggle_subtitles)
	_accessibility_row.add_child(_subtitles_button)
	_scale_button = Button.new()
	_scale_button.pressed.connect(_cycle_scale)
	_accessibility_row.add_child(_scale_button)
	_controls_label = Label.new()
	_controls_label.text = "Teclado: A/D · Espacio · Mouse · F · Esc\nGamepad: stick/D-pad · A · stick derecho/RT · X · Menu"
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_controls_label)
	_refresh_accessibility_labels()
	_refresh_profile_label()


func _show_overlay(heading: String, body: String, primary_text: String) -> void:
	_overlay.visible = true
	_heading.text = heading
	_body.text = body
	_briefing_image.visible = false
	_page_label.visible = false
	_profile_button.visible = true
	_campaign_button.visible = _host.campaign_mode
	_accessibility_row.visible = true
	_controls_label.visible = true
	_primary_button.text = primary_text
	_restart_button.visible = not _is_completion
	_primary_button.grab_focus()


func _on_primary_pressed() -> void:
	if _is_completion:
		_host.continue_after_completion()
	elif _briefing_index >= 0:
		if _briefing_index + 1 < _briefing_cards.size():
			_briefing_index += 1
			_show_briefing_card()
		else:
			_briefing_index = -1
			_resume()
	else:
		_resume()


func briefing_card_count() -> int:
	return _briefing_cards.size()


func current_briefing_index() -> int:
	return _briefing_index


func _show_briefing_card() -> void:
	var card := _briefing_cards[_briefing_index]
	_overlay.visible = true
	_heading.text = String(card.get("title", _title)).to_upper()
	_body.text = String(card.get("body", ""))
	_briefing_image.texture = _briefing_texture(card)
	_briefing_image.visible = _briefing_image.texture != null
	_page_label.visible = true
	_page_label.text = "%d / %d" % [_briefing_index + 1, _briefing_cards.size()]
	_primary_button.text = "COMENZAR" if _briefing_index + 1 == _briefing_cards.size() else "SIGUIENTE"
	_restart_button.visible = false
	_profile_button.visible = false
	_campaign_button.visible = false
	_accessibility_row.visible = false
	_controls_label.visible = false
	_primary_button.grab_focus()


func _briefing_texture(card: Dictionary) -> Texture2D:
	var image_path := String(card.get("image_path", ""))
	if image_path.is_empty():
		return null
	var source := load(image_path) as Texture2D
	if source == null:
		return null
	var columns := maxi(int(card.get("image_columns", 1)), 1)
	if columns == 1:
		return source
	var frame := clampi(int(card.get("image_frame", 0)), 0, columns - 1)
	var frame_width := float(source.get_width()) / float(columns)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(frame_width * frame, 0.0, frame_width, float(source.get_height()))
	return atlas


func _resume() -> void:
	if _host != null:
		_host.suppress_gameplay_input_until_released()
	_overlay.visible = false
	get_tree().paused = false


func _restart() -> void:
	get_tree().paused = false
	if _host != null:
		_host.call_deferred("restart_run")


func _toggle_shake() -> void:
	_settings.screen_shake_enabled = not _settings.screen_shake_enabled
	_commit_accessibility()


func _toggle_subtitles() -> void:
	_settings.subtitles_enabled = not _settings.subtitles_enabled
	_commit_accessibility()


func _cycle_scale() -> void:
	_settings.cycle_ui_scale()
	_commit_accessibility()


func _cycle_playtest_profile() -> void:
	if _host != null:
		_host.cycle_playtest_profile()
	_refresh_profile_label()


func _refresh_profile_label() -> void:
	if _profile_button == null or _host == null:
		return
	var labels := {
		&"unspecified": "SIN CLASIFICAR",
		&"first_clear": "PRIMERA VUELTA",
		&"clean_replay": "REPETICIÓN LIMPIA",
		&"completionist": "COMPLETIONIST",
	}
	var profile := _host.current_playtest_profile()
	_profile_button.text = "PERFIL DE PRUEBA: %s" % String(labels.get(profile, "SIN CLASIFICAR"))


func _commit_accessibility() -> void:
	AccessibilityStore.save_settings(_settings)
	_refresh_accessibility_labels()
	accessibility_changed.emit(_settings)


func _refresh_accessibility_labels() -> void:
	if _settings == null or _shake_button == null:
		return
	_shake_button.text = "SHAKE: %s" % ("ON" if _settings.screen_shake_enabled else "OFF")
	_subtitles_button.text = "SUBTÍTULOS: %s" % ("ON" if _settings.subtitles_enabled else "OFF")
	_scale_button.text = "UI: %d%%" % roundi(_settings.ui_scale * 100.0)
	if _panel != null:
		_panel.add_theme_font_size_override("font_size", roundi(16.0 * _settings.ui_scale))
		_heading.add_theme_font_size_override("font_size", roundi(30.0 * _settings.ui_scale))
		_body.add_theme_font_size_override("font_size", roundi(17.0 * _settings.ui_scale))
		_page_label.add_theme_font_size_override("font_size", roundi(12.0 * _settings.ui_scale))
