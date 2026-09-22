class_name RunEconomyDefinition
extends Resource

@export var items: Dictionary = {}
@export var item_art: Dictionary = {}
@export var loot_icon_size: float = 84.0
@export var loot_pixel_size: float = 3.0
@export var drop_lifetime_seconds: float = 90.0
@export var drop_warning_seconds: float = 10.0
@export var starting_items: Dictionary = {}
@export var weapons: Array[Dictionary] = []
@export var weapon_art: Array[Texture2D] = []
@export var pickup_rewards: Dictionary = {}
@export var encounter_rewards: Dictionary = {}
@export var actor_drop_rewards: Dictionary = {}
@export var loot_region := Rect2(32, 224, 32, 32)
@export_range(1.0, 4.0, 1.0) var loot_art_scale: float = 2.0
@export var loot_horizontal_offset: float = 56.0
@export var machine_costs: Dictionary = {}
@export var key_gates: Dictionary = {}
@export var offers: Dictionary = {}
@export var shop_position := Vector2.ZERO
@export var emergency_ammo: int = 20
@export var pickup_atlas: Texture2D
@export var pickup_regions: Dictionary = {}


func validation_errors(spec: LevelSpec) -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(loot_pixel_size) or loot_pixel_size < 1.0 or not is_equal_approx(loot_pixel_size, roundf(loot_pixel_size)):
		errors.append("Densidad de píxel de loot inválida")
	if not is_finite(drop_lifetime_seconds) or not is_finite(drop_warning_seconds) or drop_lifetime_seconds <= 0.0 or drop_warning_seconds <= 0.0 or drop_warning_seconds >= drop_lifetime_seconds:
		errors.append("Duración/aviso de drop inválidos")
	if not is_finite(loot_icon_size) or loot_icon_size <= 0.0:
		errors.append("Tamaño de icono de loot inválido")
	for item: String in item_art:
		if not items.has(item) or not item_art[item] is Texture2D:
			errors.append("Arte de objeto inválido: " + item)
	var bounds: Dictionary = spec.data.get("bounds", {})
	if shop_position.x < 0 or shop_position.y < 0 or shop_position.x > float(bounds.get("width", 0)) or shop_position.y > float(bounds.get("height", 0)):
		errors.append("Tienda fuera del nivel")
	if emergency_ammo <= 0:
		errors.append("Reserva de emergencia inválida")
	if not is_finite(loot_art_scale) or loot_art_scale <= 0.0:
		errors.append("Escala de loot inválida")
	if not is_finite(loot_horizontal_offset):
		errors.append("Desplazamiento de loot inválido")
	if weapons.size() != 2:
		errors.append("Se requieren dos armas")
	for weapon: Dictionary in weapons:
		if float(weapon.get("art_scale", 1.0)) <= 0.0 or float(weapon.get("projectile_scale", 2.0)) <= 0.0:
			errors.append("Escala visual de arma inválida")
		if not items.has(String(weapon.get("ammo", ""))) or float(weapon.get("damage", 0)) <= 0 or float(weapon.get("cooldown", 0)) <= 0:
			errors.append("Arma inválida")
	for item: String in starting_items:
		if not items.has(item) or int(starting_items[item]) < 0:
			errors.append("Inventario inicial inválido")
	for mapping: Dictionary in [{"values": pickup_rewards, "collection": "resources"}, {"values": encounter_rewards, "collection": "encounters"}, {"values": machine_costs, "collection": "rule_objects"}, {"values": key_gates, "collection": "gates"}]:
		var ids: Array = []
		for entry: Dictionary in spec.data.get(mapping.collection, []):
			ids.append(String(entry.id))
		for id: String in mapping["values"]:
			if id not in ids:
				errors.append("Referencia económica desconocida: " + id)
	if not actor_drop_rewards.is_empty() and (pickup_atlas == null or not Rect2(Vector2.ZERO, pickup_atlas.get_size()).encloses(loot_region)):
		errors.append("Región de loot inválida")
	for rewards: Dictionary in [pickup_rewards, encounter_rewards, actor_drop_rewards]:
		for id: String in rewards:
			var reward: Dictionary = rewards[id]
			if int(reward.get("sats", 0)) < 0:
				errors.append("Recompensa negativa: " + id)
			for item: String in reward.get("items", {}):
				if not items.has(item) or int(reward.items[item]) <= 0:
					errors.append("Stack inválido: " + id)
				elif rewards == actor_drop_rewards and bool(items[item].get("protected", false)):
					errors.append("Un objeto de misión no puede depender de un drop temporal: " + id)
	for id: String in machine_costs:
		var cost: Dictionary = machine_costs[id]
		if not items.has(String(cost.get("item", ""))) or int(cost.get("amount", 0)) <= 0:
			errors.append("Coste inválido: " + id)
			continue
		var item := String(cost.item)
		if not bool(items[item].get("protected", false)):
			errors.append("Servicio obligatorio necesita componentes protegidos: " + id)
		var machine_x := -1.0
		for machine: Dictionary in spec.data.get("rule_objects", []):
			if String(machine.id) == id:
				machine_x = float(machine.x)
		var available := int(starting_items.get(item, 0))
		for pickup: Dictionary in spec.data.get("resources", []):
			if float(pickup.x) < machine_x:
				available += int(pickup_rewards.get(String(pickup.id), {}).get("items", {}).get(item, 0))
		var required := int(cost.amount)
		for previous_id: String in machine_costs:
			var previous: Dictionary = machine_costs[previous_id]
			if previous_id == id or String(previous.item) != item:
				continue
			for machine: Dictionary in spec.data.get("rule_objects", []):
				if String(machine.id) == previous_id and float(machine.x) < machine_x:
					required += int(previous.amount)
		if available < required:
			errors.append("Faltan componentes garantizados antes del servicio: " + id)
	for id: String in key_gates:
		var item := String(key_gates[id])
		if not items.has(item) or not bool(items[item].get("protected", false)):
			errors.append("La llave debe estar protegida: " + id)
		for gate: Dictionary in spec.data.get("gates", []):
			if String(gate.id) == id and int(pickup_rewards.get(String(gate.get("key_resource_id", "")), {}).get("items", {}).get(item, 0)) <= 0:
				errors.append("El pickup no concede la llave de la puerta: " + id)
	for id: String in pickup_regions:
		if pickup_atlas == null or not pickup_rewards.has(id) or not Rect2(Vector2.ZERO, pickup_atlas.get_size()).encloses(pickup_regions[id]):
			errors.append("Región de icono inválida: " + id)
	for id: String in offers:
		var offer: Dictionary = offers[id]
		if not items.has(String(offer.get("item", ""))) or int(offer.get("amount", 0)) <= 0 or int(offer.get("price_sats", -1)) < 0:
			errors.append("Oferta inválida: " + id)
	return errors
