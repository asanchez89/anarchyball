class_name WorldLootDrops
extends Node

var economy: WorkshopEconomy
var drops: Dictionary = {}
var actors: Dictionary = {}
var legacy_tokens: Dictionary = {}
var rewards: Dictionary = {}
var retired: Dictionary = {}


func configure(service: WorkshopEconomy) -> void:
	economy = service
	for observer: EncounterRuntimeObserver in economy.builder.get_node("Generated/EncounterObservers").get_children():
		if observer.challenge != null and (observer.challenge.definition.mode == CeasefireChallengeDefinition.AttackMode.CONTACT_RAID or observer.challenge.definition.mode == CeasefireChallengeDefinition.AttackMode.MIXED_STAGES):
			for index: int in observer._actors.size():
				var thief := observer._actors[index]
				# Keep the original pickup ID for saves of the first thief.
				var recovery_id := "restitution:" + String(observer.encounter_id)
				if index > 0:
					recovery_id += ":" + String(thief.stable_id)
				rewards[recovery_id] = {"items": {}, "restitution": true}
				actors[recovery_id] = thief
				legacy_tokens[recovery_id] = recovery_id
				_create_pickup(recovery_id)
				thief.conflict_state.state_changed.connect(_on_restitution_actor_state_changed.bind(observer, thief, recovery_id))
			observer.resolved.connect(_on_restitution_encounter_resolved.bind(observer))
		var eligible: Array[CombatTarget] = []
		for actor: CombatTarget in observer._actors:
			if economy.profile.actor_drop_rewards.has(String(actor.archetype_id)):
				eligible.append(actor)
		var shared: Dictionary = economy.profile.encounter_rewards.get(String(observer.encounter_id), {}).get("items", {})
		for index: int in eligible.size():
			var actor := eligible[index]
			var reward: Dictionary = economy.profile.actor_drop_rewards[String(actor.archetype_id)].duplicate(true)
			if not shared.is_empty():
				var items: Dictionary = {}
				for item: String in shared:
					var amount := int(shared[item]) / eligible.size()
					if index < int(shared[item]) % eligible.size():
						amount += 1
					if amount > 0:
						items[item] = amount
				reward["items"] = items
			var id := "loot_" + String(actor.stable_id)
			rewards[id] = reward
			actors[id] = actor
			legacy_tokens[id] = "encounter:" + String(observer.encounter_id) if not shared.is_empty() else ""
			_create_pickup(id)
			actor.neutralized.connect(func(_actor_id: StringName) -> void: release(id))
			if bool(reward.get("cede_on_resolution", false)):
				# Voluntary abandoned goods, never permission to loot a neutral actor.
				observer.resolved.connect(func(_encounter: StringName, _resolution: StringName) -> void: release(id))


func _on_restitution_actor_state_changed(_previous: ConflictStateComponent.State, current: ConflictStateComponent.State, _reason: ConflictStateComponent.AggressorReason, observer: EncounterRuntimeObserver, actor: CombatTarget, id: String) -> void:
	if observer.challenge.restoring or current not in [ConflictStateComponent.State.SURRENDERING, ConflictStateComponent.State.NEUTRALIZED]:
		return
	_release_restitution_for_actor(observer, actor, id)


func _on_restitution_encounter_resolved(_encounter: StringName, _resolution: StringName, observer: EncounterRuntimeObserver) -> void:
	if observer.challenge.stolen_by_actor.is_empty():
		# Old checkpoints kept only the encounter total and used one package.
		var legacy_id := "restitution:" + String(observer.encounter_id)
		_prepare_restitution(legacy_id, observer.challenge.stolen)
		return
	for index: int in observer._actors.size():
		var actor := observer._actors[index]
		var id := "restitution:" + String(observer.encounter_id)
		if index > 0:
			id += ":" + String(actor.stable_id)
		_release_restitution_for_actor(observer, actor, id)


func _release_restitution_for_actor(observer: EncounterRuntimeObserver, actor: CombatTarget, id: String) -> void:
	var goods: Dictionary = observer.challenge.stolen_by_actor.get(String(actor.stable_id), {})
	_prepare_restitution(id, goods)


func _prepare_restitution(id: String, goods: Dictionary) -> void:
	if goods.is_empty() or retired.has(id) or economy.player.inventory.claimed.has(id) or not drops.has(id):
		return
	rewards[id]["items"] = goods.duplicate(true)
	var pickup := drops[id] as DebugPickup
	pickup.inventory_reward = rewards[id]
	pickup.display_text = "RECUPERA TUS OBJETOS · " + economy.reward_text(rewards[id])
	release(id)


func _create_pickup(id: String) -> DebugPickup:
	var pickup := DebugPickup.new()
	pickup.name = id
	pickup.pickup_id = StringName(id)
	pickup.pickup_kind = &"salvage"
	pickup.ownership = &"permitted_salvage"
	pickup.inventory_reward = rewards[id]
	pickup.display_text = "RESTOS ABANDONADOS · " + economy.reward_text(rewards[id])
	pickup.configure_lifetime(economy.profile.drop_lifetime_seconds, economy.profile.drop_warning_seconds)
	pickup.set_available(false)
	economy.builder.get_node("Generated/Resources").add_child(pickup)
	pickup.set_art(economy.profile.pickup_atlas, economy.profile.loot_region, economy.profile.loot_art_scale)
	for item: String in rewards[id].get("items", {}):
		if economy.profile.item_art.has(item):
			var texture := economy.profile.item_art[item] as Texture2D
			var region := texture.get_image().get_used_rect()
			pickup.set_pixel_grid_art(texture, Rect2(region), economy.profile.loot_icon_size, economy.profile.loot_pixel_size)
			break
	pickup.collected.connect(economy.builder._on_pickup_collected.bind(pickup.ownership))
	if bool(rewards[id].get("restitution", false)):
		pickup.configure_lifetime(0.0, 0.0)
		var package := preload("res://assets/art/props/world_0/workshop_crate.png")
		pickup.set_art(package, Rect2(package.get_image().get_used_rect()), World0ArtMetrics.PICKUP_SCALE)
	pickup.collected.connect(func(_pickup_id: StringName) -> void: _retire(id, false))
	pickup.expired.connect(func(_pickup_id: StringName) -> void: _retire(id, true))
	drops[id] = pickup
	return pickup


func _retire(id: String, expired: bool) -> void:
	if not drops.has(id):
		return
	retired[id] = _snapshot(drops[id])
	retired[id]["expired"] = expired
	retired[id]["collected"] = not expired
	retired[id]["available"] = false
	_dispose_live(id)


func _dispose_live(id: String) -> void:
	if not drops.has(id):
		return
	var pickup := drops[id] as DebugPickup
	drops.erase(id)
	pickup.set_available(false)
	# A retry can recreate this stable ID before the deferred deletion runs.
	pickup.name = id + "_retired_" + str(pickup.get_instance_id())
	pickup.queue_free()


func _snapshot(pickup: DebugPickup) -> Dictionary:
	return {"available": pickup.is_available(), "x": pickup.position.x, "y": pickup.position.y, "remaining": pickup.remaining_seconds, "expired": false, "collected": pickup.is_collected(), "motion": pickup.capture_drop_motion(), "reward": pickup.inventory_reward.duplicate(true)}


func release(id: String) -> void:
	if retired.has(id) or economy.player.inventory.claimed.has(id) or not drops.has(id):
		return
	var pickup := drops[id] as DebugPickup
	if pickup.is_available() or pickup.is_collected():
		return
	var actor := actors[id] as CombatTarget
	var origin := (pickup.get_parent() as Node2D).to_local(actor.global_position)
	pickup.launch_drop(origin, _drop_position(id))


func _drop_position(id: String) -> Vector2:
	var actor := actors[id] as CombatTarget
	var pickup := drops[id] as DebugPickup
	var base := economy.builder._grounded_placement(actor.position.x, actor.position.y, pickup.visible_floor_offset())
	var beside := economy.builder._grounded_placement(actor.position.x + economy.profile.loot_horizontal_offset, actor.position.y, pickup.visible_floor_offset())
	# Keep loot on the same supporting surface if the actor fell beside a ledge.
	return beside if is_equal_approx(base.y, beside.y) else base


func capture() -> Dictionary:
	var state: Dictionary = retired.duplicate(true)
	for id: String in drops:
		state[id] = _snapshot(drops[id])
	return state


func restore(state: Dictionary) -> void:
	retired.clear()
	for id: String in rewards:
		var saved: Dictionary = state.get(id, {})
		if bool(rewards[id].get("restitution", false)):
			rewards[id]["items"] = saved.get("reward", {}).get("items", {}).duplicate(true)
		var claimed := economy.player.inventory.claimed.has(id)
		if saved.is_empty():
			# Older saves already credited encounter loot directly.
			claimed = claimed or economy.player.inventory.claimed.has(String(legacy_tokens[id]))
		var expired := bool(saved.get("expired", false))
		claimed = claimed or bool(saved.get("collected", false))
		if claimed or expired:
			retired[id] = saved.duplicate(true)
			retired[id].merge({"collected": claimed, "expired": expired, "available": false}, true)
			_dispose_live(id)
			continue
		var pickup: DebugPickup = drops[id] if drops.has(id) else _create_pickup(id)
		pickup.inventory_reward = rewards[id]
		if bool(rewards[id].get("restitution", false)):
			pickup.display_text = "RECUPERA TUS OBJETOS · " + economy.reward_text(rewards[id])
		pickup.position = _drop_position(id) if saved.is_empty() else Vector2(float(saved.x), float(saved.y))
		pickup.restore_collected(false)
		pickup.restore_lifetime(float(saved.get("remaining", economy.profile.drop_lifetime_seconds)))
		pickup.restore_drop_motion(saved.get("motion", {}))
		var default_available := not bool(rewards[id].get("restitution", false)) and (actors[id] as CombatTarget).conflict_state.current_state == ConflictStateComponent.State.NEUTRALIZED
		pickup.set_available(bool(saved.get("available", default_available)))
