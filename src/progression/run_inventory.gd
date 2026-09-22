class_name RunInventory
extends RefCounted

signal changed()

var profile: RunEconomyDefinition
var stacks: Dictionary = {}
var claimed: Dictionary = {}
var satoshis: int = 0


func configure(value: RunEconomyDefinition) -> void:
	profile = value
	stacks = value.starting_items.duplicate(true)
	claimed.clear()
	satoshis = 0
	changed.emit()


func count(item_id: String) -> int:
	return int(stacks.get(item_id, 0))


func grant_once(reward_id: String, items: Dictionary, sats: int = 0) -> bool:
	if claimed.has(reward_id) or reward_id.is_empty() or sats < 0:
		return false
	for item: String in items:
		if not profile.items.has(item) or int(items[item]) <= 0:
			return false
	for item: String in items:
		stacks[item] = count(item) + int(items[item])
	satoshis += sats
	claimed[reward_id] = true
	changed.emit()
	return true


func spend(item: String, amount: int) -> bool:
	if amount <= 0 or count(item) < amount:
		return false
	stacks[item] = count(item) - amount
	changed.emit()
	return true


func pay_service(service_id: String, item: String, amount: int) -> bool:
	var token := "service:" + service_id
	if claimed.has(token):
		return true
	if not spend(item, amount):
		return false
	claimed[token] = true
	return true


func sell(item: String, amount: int) -> bool:
	var data: Dictionary = profile.items.get(item, {})
	var price := int(data.get("sell_sats", 0))
	if price <= 0 or bool(data.get("protected", false)) or not spend(item, amount):
		return false
	satoshis += amount * price
	changed.emit()
	return true


func buy(offer_id: String) -> bool:
	var offer: Dictionary = profile.offers.get(offer_id, {})
	var price := int(offer.get("price_sats", -1))
	if price < 0 or satoshis < price or offer.is_empty():
		return false
	var item := String(offer.item)
	stacks[item] = count(item) + int(offer.amount)
	satoshis -= price
	changed.emit()
	return true


func capture() -> Dictionary:
	return {"version": 1, "stacks": stacks.duplicate(true), "claimed": claimed.duplicate(true), "sats": satoshis}


func restore(data: Dictionary) -> void:
	configure(profile)
	if int(data.get("version", 0)) != 1:
		return
	stacks.clear()
	for item: String in data.get("stacks", {}):
		if profile.items.has(item):
			stacks[item] = maxi(0, int(data.stacks[item]))
	claimed = (data.get("claimed", {}) as Dictionary).duplicate(true)
	satoshis = maxi(0, int(data.get("sats", 0)))
	changed.emit()
