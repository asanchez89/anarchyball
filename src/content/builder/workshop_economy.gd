class_name WorkshopEconomy
extends Node

var profile: RunEconomyDefinition
var player: PlayerController
var builder: LevelBuilder
var shop: RuleStateObject
var _menu: CanvasLayer
var _summary: Label
var _message: Label
var loot: WorldLootDrops
var player_menu: PlayerInventoryMenu
var _service_menu: CanvasLayer
var _pending_service: String = ""
var _service_was_paused: bool = false
var _shop_options: VBoxContainer
var _shop_page: String = "home"
var _sale_item: String = ""
var _sale_quantity: int = 1
var _sale_total: Label


class ShopOverlay extends CanvasLayer:
	var close_requested: Callable

	func _input(event: InputEvent) -> void:
		if event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close_requested.call()


class TradeTerminal extends RuleStateObject:
	var open_menu: Callable

	func interaction_caption() -> String:
		return "SHOP"

	func interaction_available() -> bool:
		return true

	func _texture_for_machine() -> Texture2D:
		return preload("res://assets/art/props/world_0/bitcoin_atm_terminal.png")

	func _ready() -> void:
		super._ready()
		_machine_sprite.scale = Vector2.ONE * World0ArtMetrics.SCENERY_PROP_SCALE
		var visible_rect := _machine_sprite.texture.get_image().get_used_rect()
		_machine_sprite.position.y = -(visible_rect.end.y - _machine_sprite.texture.get_height() * 0.5) * World0ArtMetrics.SCENERY_PROP_SCALE
		var badge := Label.new()
		badge.text = "BTC"
		badge.add_theme_font_override("font", preload("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf"))
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", Color("ffca45"))
		badge.position = Vector2(-15, -95)
		add_child(badge)
		_interaction_beacon.configure(_machine_sprite, "SHOP", Color("ffca45"))
		_label.position = Vector2(-135, -210)
		_label.size = Vector2(270, 60)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_update_label()

	func _update_label() -> void:
		if _label != null:
			_label.text = "F / X · Comprar / Vender"
			_label.visible = _player_nearby

	func interact() -> bool:
		open_menu.call()
		return true


func configure(level: LevelBuilder, definition: RunEconomyDefinition) -> void:
	builder = level
	profile = definition
	player = level.get_node("Generated/Player") as PlayerController
	player.inventory = RunInventory.new()
	player.inventory.configure(profile)
	for id: String in profile.pickup_rewards:
		var pickup := level.get_node("Generated/Resources/" + id) as DebugPickup
		pickup.inventory_reward = profile.pickup_rewards[id]
		pickup.display_text = reward_text(pickup.inventory_reward)
		if profile.pickup_atlas != null and profile.pickup_regions.has(id):
			pickup.set_art(profile.pickup_atlas, profile.pickup_regions[id])
		pickup.queue_redraw()
	for id: String in profile.key_gates:
		var gate := level.get_node("Generated/Gates/" + id) as AccessGate
		gate.inventory = player.inventory
		gate.required_key = String(profile.key_gates[id])
		gate._update_label()
	for id: String in profile.machine_costs:
		var machine := level.get_node("Generated/RuleObjects/" + id) as RuleStateObject
		machine.activation_payment = pay_machine.bind(id)
		var cost: Dictionary = profile.machine_costs[id]
		machine.action_hint = "F / X: servicio · %d %s (pago único)" % [int(cost.amount), String(profile.items[String(cost.item)].label)]
		machine._update_label()
	for id: String in profile.encounter_rewards:
		var observer := level.get_node("Generated/EncounterObservers/" + id) as EncounterRuntimeObserver
		observer.resolved.connect(_reward_encounter)
	shop = TradeTerminal.new()
	shop.name = "WorkshopShop"
	(shop as TradeTerminal).open_menu = open_shop
	shop.position = builder._grounded_placement(profile.shop_position.x, profile.shop_position.y)
	shop.machine_label = "ATM BITCOIN · SUMINISTROS"
	shop.action_hint = "F / X: vender loot, comprar munición o curación"
	shop.current_state = RuleStateObject.State.AVAILABLE
	level.get_node("Generated").add_child(shop)
	loot = WorldLootDrops.new()
	add_child(loot)
	loot.configure(self)
	player_menu = PlayerInventoryMenu.new()
	add_child(player_menu)
	player_menu.configure(self)


func reward_text(reward: Dictionary) -> String:
	var parts := PackedStringArray()
	for item: String in reward.get("items", {}):
		parts.append("%s ×%d" % [String(profile.items[item].label), int(reward.items[item])])
	if int(reward.get("sats", 0)) > 0:
		parts.append("%d sats" % int(reward.sats))
	return " · ".join(parts)


func pay_machine(id: String) -> bool:
	if player.inventory.claimed.has("service:" + id):
		return true
	if _service_menu == null:
		open_service(id)
	return false


func open_service(id: String) -> void:
	_pending_service = id
	_service_was_paused = get_tree().paused
	_service_menu = ShopOverlay.new()
	(_service_menu as ShopOverlay).close_requested = close_service
	_service_menu.layer = 80
	_service_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_service_menu)
	_service_menu.add_to_group("shop_overlay")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_service_menu.add_child(dim)
	var panel := PanelContainer.new()
	panel.theme = preload("res://assets/ui/game_theme.tres")
	panel.position = Vector2(180, 180)
	panel.custom_minimum_size = Vector2(920, 340)
	_service_menu.add_child(panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 20)
	panel.add_child(list)
	var cost: Dictionary = profile.machine_costs[id]
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 820
	label.add_theme_font_size_override("font_size", 18)
	var owned := player.inventory.count(String(cost.item))
	label.text = "SERVICIO MUTUALIST\n\nPara habilitar esta máquina necesito:\n%d × %s · Tienes: %d\nPago único. No se descuenta nada hasta aceptar." % [int(cost.amount), String(profile.items[String(cost.item)].label), owned]
	list.add_child(label)
	var accept := _button(list, "Pagar y activar" if owned >= int(cost.amount) else "Faltan %d componentes: explora el taller" % (int(cost.amount) - owned))
	accept.disabled = owned < int(cost.amount)
	accept.pressed.connect(confirm_service)
	var cancel := _button(list, "Cancelar · conservar mis objetos")
	cancel.pressed.connect(close_service)
	get_tree().paused = true
	# Cancellation is the default, so the input opening this menu cannot pay.
	cancel.grab_focus()


func confirm_service() -> bool:
	if _pending_service.is_empty():
		return false
	var id := _pending_service
	var machine := builder.get_node("Generated/RuleObjects/" + id) as RuleStateObject
	var cost: Dictionary = profile.machine_costs[id]
	if not machine.prerequisites_met() or machine.current_state not in [RuleStateObject.State.AVAILABLE, RuleStateObject.State.ABANDONED]:
		close_service()
		return false
	if not player.inventory.pay_service(id, String(cost.item), int(cost.amount)):
		close_service()
		return false
	close_service()
	var activated := machine.interact()
	if activated and builder._hud != null:
		builder._hud.show_feedback("MUTUALIST · PAGO RECIBIDO: %d × %s · máquina habilitada" % [int(cost.amount), String(profile.items[String(cost.item)].label)])
	return activated


func close_service() -> void:
	if _service_menu == null:
		return
	_service_menu.queue_free()
	_service_menu = null
	_pending_service = ""
	get_tree().paused = _service_was_paused
	player.suppress_gameplay_input_until_released()


func _reward_encounter(id: StringName, _resolution: StringName) -> void:
	var reward: Dictionary = profile.encounter_rewards.get(String(id), {})
	# Item rewards are physical salvage; currency remains a mission payment.
	var observer := builder.get_node("Generated/EncounterObservers/" + String(id)) as EncounterRuntimeObserver
	var physical := observer._actors.any(func(actor: CombatTarget) -> bool: return profile.actor_drop_rewards.has(String(actor.archetype_id)))
	var items: Dictionary = {} if physical else reward.get("items", {})
	if player.inventory.grant_once("encounter:" + String(id), items, int(reward.get("sats", 0))):
		if builder._hud != null:
			builder._hud.show_feedback("PUESTO LIBERADO · recoge el loot abandonado" if physical else "RECOMPENSA · " + reward_text(reward))


func buy(offer: String) -> bool:
	if not profile.offers.has(offer):
		return false
	var data: Dictionary = profile.offers[offer]
	if String(data.item) == "healing" and player.health.current_health >= player.health.maximum_health:
		return false
	if not player.inventory.buy(offer):
		return false
	if String(data.item) == "healing":
		player.inventory.spend("healing", int(data.amount))
		player.health.heal(float(data.amount))
	return true


func emergency_supply() -> bool:
	# Reachable starting depot; finite-ammo progression must never hard-lock.
	if player.inventory.count("light_ammo") > 0 or player.inventory.count("heavy_ammo") > 0:
		return false
	player.inventory.stacks["light_ammo"] = profile.emergency_ammo
	player.inventory.changed.emit()
	return true


func open_shop() -> void:
	if _menu != null:
		return
	_menu = ShopOverlay.new()
	(_menu as ShopOverlay).close_requested = shop_back
	_menu.layer = 80
	_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu)
	_menu.add_to_group("shop_overlay")
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "ShopPanel"
	panel.theme = preload("res://assets/ui/game_theme.tres")
	panel.position = Vector2(130, 30)
	panel.size = Vector2(1020, 660)
	_menu.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "ShopScroll"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var title := Label.new()
	title.text = "PUESTO DE SUMINISTROS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("ffdb55"))
	list.add_child(title)
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 14)
	list.add_child(_summary)
	_shop_options = VBoxContainer.new()
	_shop_options.add_theme_constant_override("separation", 10)
	list.add_child(_shop_options)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.y = 34
	_message.add_theme_color_override("font_color", Color("76e6ff"))
	_message.text = "FLECHAS / D-PAD: ELEGIR · ENTER / A: ACEPTAR · ESC / B: SALIR"
	_message.add_theme_font_size_override("font_size", 12)
	list.add_child(_message)
	_update_summary()
	get_tree().paused = true
	show_shop_page("home")


func sellable_items() -> Array[String]:
	var items: Array[String] = []
	for item: String in profile.items:
		var data: Dictionary = profile.items[item]
		if player.inventory.count(item) > 0 and int(data.get("sell_sats", 0)) > 0 and not bool(data.get("protected", false)):
			items.append(item)
	return items


func show_shop_page(page: String) -> void:
	_shop_page = page
	_sale_item = ""
	for child: Node in _shop_options.get_children():
		_shop_options.remove_child(child)
		child.queue_free()
	if page == "home":
		_button(_shop_options, "COMPRAR · suministros").pressed.connect(show_shop_page.bind("buy"))
		_button(_shop_options, "VENDER · abrir mi inventario").pressed.connect(show_shop_page.bind("sell"))
		_button(_shop_options, "Reserva gratuita (solo sin munición)").pressed.connect(func() -> void: _transaction_feedback(emergency_supply()))
	elif page == "buy":
		for id: String in profile.offers:
			var offer: Dictionary = profile.offers[id]
			var button := _button(_shop_options, "%s ×%d — %d sats" % [profile.items[String(offer.item)].label, int(offer.amount), int(offer.price_sats)])
			button.pressed.connect(func() -> void: _transaction_feedback(buy(id)))
	elif page == "sell":
		for item: String in sellable_items():
			_button(_shop_options, "%s ×%d · %d sats/unidad" % [profile.items[item].label, player.inventory.count(item), int(profile.items[item].sell_sats)]).pressed.connect(select_sale.bind(item))
		if sellable_items().is_empty():
			var empty := Label.new()
			empty.text = "No tienes objetos para vender."
			_shop_options.add_child(empty)
	_button(_shop_options, "Salir" if page == "home" else "Volver").pressed.connect(shop_back)
	for node: Node in _shop_options.get_children():
		if node is Button:
			(node as Button).grab_focus()
			break
	_message.text = "FLECHAS / D-PAD: ELEGIR · ENTER / A: ACEPTAR · ESC / B: VOLVER"


func select_sale(item: String) -> void:
	if item not in sellable_items():
		return
	show_shop_page("quantity")
	_sale_item = item
	_sale_quantity = 1
	_sale_total = Label.new()
	_sale_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sale_total.custom_minimum_size = Vector2(820, 90)
	_shop_options.add_child(_sale_total)
	_shop_options.move_child(_sale_total, 0)
	var quantities := HBoxContainer.new()
	quantities.add_theme_constant_override("separation", 10)
	_shop_options.add_child(quantities)
	for delta: int in [-10, -1, 1, 10]:
		var step := _button(quantities, "%+d" % delta)
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.pressed.connect(change_sale_quantity.bind(delta))
	_button(_shop_options, "Seleccionar todas las unidades").pressed.connect(change_sale_quantity.bind(player.inventory.count(item)))
	var confirm := _button(_shop_options, "Confirmar venta")
	confirm.pressed.connect(confirm_sale)
	_shop_options.move_child(_shop_options.get_child(1), _shop_options.get_child_count() - 1)
	change_sale_quantity(0)
	# Back remains focused until the player deliberately chooses an action.


func change_sale_quantity(delta: int) -> void:
	if _sale_item.is_empty():
		return
	_sale_quantity = clampi(_sale_quantity + delta, 1, maxi(1, player.inventory.count(_sale_item)))
	_sale_total.text = "%s · Disponibles: %d\nCantidad: %d · Recibirás: %d sats" % [profile.items[_sale_item].label, player.inventory.count(_sale_item), _sale_quantity, _sale_quantity * int(profile.items[_sale_item].sell_sats)]


func confirm_sale() -> bool:
	if _sale_item.is_empty():
		return false
	var item := _sale_item
	var quantity := _sale_quantity
	var total := quantity * int(profile.items[item].sell_sats)
	var success := player.inventory.sell(item, quantity)
	show_shop_page("sell")
	_transaction_feedback(success)
	if success:
		_message.text = "Vendido: %s ×%d · +%d sats" % [profile.items[item].label, quantity, total]
	return success


func shop_back() -> void:
	if _shop_page == "home":
		close_shop()
	else:
		show_shop_page("sell" if _shop_page == "quantity" else "home")


func close_shop() -> void:
	if _menu == null:
		return
	_menu.queue_free()
	_menu = null
	get_tree().paused = false
	player.suppress_gameplay_input_until_released()


func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	parent.add_child(button)
	return button


func _transaction_feedback(success: bool) -> void:
	_message.text = "Operación completada" if success else "No disponible: revisa saldo, existencias o salud"
	_update_summary()
	if success:
		player.sfx.play_cue(&"rule_interaction")


func _update_summary() -> void:
	_summary.text = "SALDO: %d sats · Bitcoin ficticio" % player.inventory.satoshis
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size = Vector2(900, 74)
