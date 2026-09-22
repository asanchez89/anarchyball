class_name PlayerInventoryMenu
extends Node

var economy: WorkshopEconomy
var overlay: CanvasLayer
var stats: Label
var inventory_label: Label


class MenuOverlay extends CanvasLayer:
	var close_requested: Callable
	var inventory_scroll: ScrollContainer

	func _input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true):
			inventory_scroll.scroll_vertical += 48 if event.is_action_pressed("ui_down", true) else -48
			get_viewport().set_input_as_handled()
			return
		if event.is_echo():
			return
		if event.is_action_pressed(InputActions.PLAYER_MENU) or event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close_requested.call()


func configure(service: WorkshopEconomy) -> void:
	economy = service


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_echo() and event.is_action_pressed(InputActions.PLAYER_MENU):
		open_menu()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	if overlay != null or get_tree().paused or economy.player.health.current_health <= 0:
		return
	overlay = MenuOverlay.new()
	(overlay as MenuOverlay).close_requested = close_menu
	overlay.layer = 85
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)
	overlay.add_to_group("player_menu_overlay")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "PlayerPanel"
	panel.theme = preload("res://assets/ui/game_theme.tres")
	panel.position = Vector2(90, 35)
	panel.size = Vector2(1100, 650)
	overlay.add_child(panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 20)
	panel.add_child(list)
	var heading := _label(list, "ANARCHYBALL · EQUIPO E INVENTARIO", 22)
	heading.add_theme_color_override("font_color", Color("ffdb55"))
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 32)
	list.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 470
	left.add_theme_constant_override("separation", 20)
	columns.add_child(left)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(128, 110)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var frame := AtlasTexture.new()
	frame.atlas = preload("res://assets/art/actors/balls/world_0/runtime/anarchy_ball_keyposes.png")
	frame.region = Rect2(0, 0, 96, 96)
	portrait.texture = frame
	left.add_child(portrait)
	stats = _label(left, stats_text(), 14)
	stats.name = "Stats"
	var scroll := ScrollContainer.new()
	(overlay as MenuOverlay).inventory_scroll = scroll
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 22)
	scroll.add_child(right)
	_label(right, "INVENTARIO", 18).add_theme_color_override("font_color", Color("76e6ff"))
	inventory_label = _label(right, inventory_text(), 14)
	inventory_label.name = "Inventory"
	_label(list, "FLECHAS / D-PAD: SCROLL · I / VIEW / ESC / B: VOLVER", 12)
	var close := Button.new()
	close.text = "VOLVER AL TALLER"
	close.custom_minimum_size.y = 48
	list.add_child(close)
	close.pressed.connect(close_menu)
	get_tree().paused = true
	close.grab_focus()


func close_menu() -> void:
	if overlay == null:
		return
	overlay.queue_free()
	overlay = null
	get_tree().paused = false
	economy.player.suppress_gameplay_input_until_released()


func stats_text() -> String:
	var player := economy.player
	var lines := PackedStringArray([
		"VIDA: %.0f / %.0f" % [player.health.current_health, player.health.maximum_health],
		"VELOCIDAD: %.0f px/s" % player.movement_profile.run_speed,
		"SALDO: %d sats" % player.inventory.satoshis,
	])
	for index: int in economy.profile.weapons.size():
		var weapon: Dictionary = economy.profile.weapons[index]
		lines.append("ARMA %d · %s\nDaño: %.0f · %.2f s/disparo\nMunición: %d" % [index + 1, "PRIMARIA" if index == 0 else "SECUNDARIA", float(weapon.damage), float(weapon.cooldown), player.inventory.count(String(weapon.ammo))])
	return "\n\n".join(lines)


func inventory_text() -> String:
	var lines := PackedStringArray()
	for id: String in economy.profile.items:
		var item: Dictionary = economy.profile.items[id]
		var amount := economy.player.inventory.count(id)
		var detail := ""
		if bool(item.get("protected", false)):
			detail = "\nMisión · no vendible"
		elif int(item.get("sell_sats", 0)) > 0:
			detail = "\nVenta: %d sats/unidad" % int(item.sell_sats)
		if item.has("description"):
			detail += "\n" + String(item.description)
		lines.append("%s  ×%d%s" % [String(item.label), amount, detail])
	return "\n\n".join(lines)


func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label
