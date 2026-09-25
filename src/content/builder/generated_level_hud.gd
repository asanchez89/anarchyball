class_name GeneratedLevelHud
extends CanvasLayer

var _spec: LevelSpec
var _telemetry: LocalRunTelemetry
var _player: PlayerController
var _profile: PlayerMovementProfile
var _objective: String
var _rule_text: String
var _health: HealthComponent
var _ability: ContractorDefensiveResponse
var _boss: CombatTarget
var _status_label: Label
var _health_bar: ProgressBar
var _ability_bar: ProgressBar
var _boss_bar: ProgressBar
var _boss_label: Label
var _feedback_label: Label
var _subtitle_label: Label
var _audio_cue_label: Label
var _panel: VBoxContainer
var _settings: AccessibilitySettings
var _feedback_remaining: float = 0.0
var _audio_cue_remaining: float = 0.0


func configure(
	spec: LevelSpec,
	telemetry: LocalRunTelemetry,
	player: PlayerController,
	profile: PlayerMovementProfile,
	objective: String = "Reach the exit",
	rule_text: String = ""
) -> void:
	_spec = spec
	_telemetry = telemetry
	_player = player
	_profile = profile
	_objective = objective
	_rule_text = rule_text


func apply_accessibility(settings: AccessibilitySettings) -> void:
	_settings = settings
	if _panel != null:
		_panel.scale = Vector2.ONE * settings.ui_scale
	if _feedback_label != null:
		_feedback_label.scale = Vector2.ONE * settings.ui_scale
	if _subtitle_label != null:
		_subtitle_label.scale = Vector2.ONE * settings.ui_scale
		_subtitle_label.visible = settings.subtitles_enabled and _feedback_remaining > 0.0


func _ready() -> void:
	_health = _player.get_node("Health") as HealthComponent
	_ability = _player.get_node_or_null("ContractorDefensiveResponse") as ContractorDefensiveResponse
	for candidate: Node in _player.get_parent().find_children("*", "", true, false):
		if candidate is CombatTarget and (candidate as CombatTarget).is_boss:
			var target := candidate as CombatTarget
			_boss = target
			break
	_panel = VBoxContainer.new()
	_panel.position = Vector2(18.0, 16.0)
	_panel.size = Vector2(520.0, 220.0)
	_panel.add_theme_constant_override("separation", 5)
	add_child(_panel)
	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(500.0, 82.0)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_status_label)
	_health_bar = _make_bar(Color("76b7d8"))
	_panel.add_child(_health_bar)
	_ability_bar = _make_bar(Color("f4b942"))
	_panel.add_child(_ability_bar)
	_boss_label = Label.new()
	_boss_label.text = "COMMANDER RESOLVE"
	_panel.add_child(_boss_label)
	_boss_bar = _make_bar(Color("e65f65"))
	_panel.add_child(_boss_bar)
	_feedback_label = Label.new()
	_feedback_label.position = Vector2(550.0, 36.0)
	_feedback_label.size = Vector2(700.0, 76.0)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.add_theme_font_size_override("font_size", 20)
	_feedback_label.add_theme_color_override("font_color", Color("f4b942"))
	add_child(_feedback_label)
	_subtitle_label = Label.new()
	_subtitle_label.position = Vector2(240.0, 650.0)
	_subtitle_label.size = Vector2(800.0, 42.0)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 17)
	_subtitle_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_subtitle_label)
	_audio_cue_label = Label.new()
	_audio_cue_label.position = Vector2(930.0, 675.0)
	_audio_cue_label.size = Vector2(330.0, 28.0)
	_audio_cue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_audio_cue_label.add_theme_font_size_override("font_size", 12)
	_audio_cue_label.add_theme_color_override("font_color", Color("76e6ff"))
	add_child(_audio_cue_label)
	if _settings != null:
		apply_accessibility(_settings)


func primary_magazine_text() -> String:
	if _player.inventory == null:
		return ""
	var capacity := int(_player.inventory.profile.weapons[0].get("magazine_size", 0))
	if capacity <= 0:
		return ""
	var launcher := _player.probe_launcher
	var ready := launcher.magazine_remaining(0, capacity)
	var segments := ""
	for index: int in capacity:
		segments += "[■]" if index < ready else "[ ]"
	var remaining := launcher.reload_remaining(0)
	return "ARMA 1 %s · %s" % [segments, "RECARGA %.1f s" % remaining if remaining > 0.0 else "LISTA"]


func _process(delta: float) -> void:
	if _spec == null or _telemetry == null or _player == null or _profile == null:
		return
	_health_bar.max_value = _health.maximum_health
	_health_bar.value = _health.current_health
	_health_bar.tooltip_text = "Health %.0f / %.0f" % [_health.current_health, _health.maximum_health]
	var ability_active := _ability != null and _ability.is_active()
	_ability_bar.value = _ability.normalized_remaining() * 100.0 if ability_active else 0.0
	_status_label.text = "CONTRACTOR · HEALTH %.0f/%.0f · PROBE ∞\nOBJECTIVE: %s\nRULE: %s\nDEFENSIVE RESPONSE: %s" % [
		_health.current_health,
		_health.maximum_health,
		_objective,
		_rule_text,
		"ACTIVE %.1fs" % _ability.remaining if ability_active else "READY ON AGGRESSION",
	]
	if _player.inventory != null:
		var inventory := _player.inventory
		_status_label.text = _status_label.text.replace("PROBE ∞", "LIGERA %d · PESADA %d · BTC %d sats" % [inventory.count("light_ammo"), inventory.count("heavy_ammo"), inventory.satoshis])
		_status_label.text += "\nI / VIEW: ESTADÍSTICAS E INVENTARIO"
		_status_label.text += "\n" + primary_magazine_text()
	var boss_visible := _boss != null and _boss.conflict_state.current_state in [
		ConflictStateComponent.State.THREATENING,
		ConflictStateComponent.State.AGGRESSOR,
		ConflictStateComponent.State.SURRENDERING,
	]
	_boss_label.visible = boss_visible
	_boss_bar.visible = boss_visible
	if boss_visible:
		_boss_bar.max_value = _boss.resolve.maximum_resolve
		_boss_bar.value = _boss.resolve.current_resolve
	_feedback_remaining = maxf(_feedback_remaining - delta, 0.0)
	_audio_cue_remaining = maxf(_audio_cue_remaining - delta, 0.0)
	_feedback_label.visible = _feedback_remaining > 0.0
	_subtitle_label.visible = _settings != null and _settings.subtitles_enabled and _feedback_remaining > 0.0 and not _subtitle_label.text.is_empty()
	_audio_cue_label.visible = _audio_cue_remaining > 0.0


func show_feedback(message: String, duration: float = 2.0, subtitle: String = "") -> void:
	_feedback_label.text = message
	_subtitle_label.text = subtitle
	_feedback_remaining = duration
	_feedback_label.visible = true


func show_audio_cue(source_name: String, cue_id: StringName) -> void:
	if _audio_cue_label == null:
		return
	_audio_cue_label.text = "SFX · %s / %s" % [source_name, String(cue_id)]
	_audio_cue_remaining = 1.5
	_audio_cue_label.visible = true


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(360.0, 18.0)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill)
	return bar
