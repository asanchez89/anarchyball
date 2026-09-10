class_name AccessibilitySettings
extends Resource

const SCHEMA_VERSION: int = 0
const UI_SCALES: Array[float] = [1.0, 1.15, 1.3]

@export var screen_shake_enabled: bool = true
@export var subtitles_enabled: bool = true
@export_range(1.0, 1.3, 0.05) var ui_scale: float = 1.0


func cycle_ui_scale() -> float:
	var closest_index: int = 0
	var closest_distance: float = INF
	for index: int in UI_SCALES.size():
		var distance := absf(UI_SCALES[index] - ui_scale)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = index
	ui_scale = UI_SCALES[(closest_index + 1) % UI_SCALES.size()]
	return ui_scale


func to_dictionary() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"screen_shake_enabled": screen_shake_enabled,
		"subtitles_enabled": subtitles_enabled,
		"ui_scale": ui_scale,
	}


static func from_dictionary(data: Dictionary) -> AccessibilitySettings:
	var settings := AccessibilitySettings.new()
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return settings
	settings.screen_shake_enabled = bool(data.get("screen_shake_enabled", true))
	settings.subtitles_enabled = bool(data.get("subtitles_enabled", true))
	var requested_scale := float(data.get("ui_scale", 1.0))
	settings.ui_scale = UI_SCALES[0]
	for candidate: float in UI_SCALES:
		if absf(candidate - requested_scale) < absf(settings.ui_scale - requested_scale):
			settings.ui_scale = candidate
	return settings
