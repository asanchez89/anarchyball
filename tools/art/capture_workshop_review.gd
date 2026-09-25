extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1280, 720)
	if "--menu" in OS.get_cmdline_user_args():
		root.add_child(load("res://levels/campaign/campaign_shell.tscn").instantiate())
		for frame: int in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/menu.png")
		quit()
		return
	var level := load("res://levels/world_0/w0_01_coalition_workshop.tscn").instantiate() as Node2D
	level.set("start_in_menu", false)
	root.add_child(level)
	for frame: int in 4:
		await process_frame
	if "--mixed-live" in OS.get_cmdline_user_args():
		var actor_player := level.get_node("Generated/Player") as PlayerController
		actor_player.set_physics_process(false)
		for node: Node in level.find_children("*", "", true, false):
			if node is CombatTarget:
				node.set_process(false)
			elif node is CeasefireChallenge:
				node.set_physics_process(false)
		var observer := level.get_node("Generated/EncounterObservers/p3_final_coalition") as EncounterRuntimeObserver
		var challenge := observer.challenge
		actor_player.reset_at(Vector2(37900, 578))
		challenge._stage_elapsed = 36.0
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(37950, 360)
		review_camera.make_current()
		var key := observer._actors[4].stable_id
		for frame: int in 360:
			challenge.advance(1.0 / 60.0)
			await physics_frame
			if bool(challenge._encirclements.get(key, {}).get("armed", false)):
				break
		challenge._update_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/mixed_live.png")
		quit()
		return
	if "--pulse-vfx" in OS.get_cmdline_user_args() or "--pulse-upper" in OS.get_cmdline_user_args():
		level.process_mode = Node.PROCESS_MODE_DISABLED
		var actor_player := level.get_node("Generated/Player") as PlayerController
		var observer := level.get_node("Generated/EncounterObservers/p3_pulse_intro") as EncounterRuntimeObserver
		var challenge := observer.challenge
		actor_player.reset_at(Vector2(28820, 638) if "--pulse-upper" in OS.get_cmdline_user_args() else Vector2(28650, 658))
		challenge.advance(challenge.definition.warning_seconds)
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(28780, 360)
		review_camera.make_current()
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		for phase: int in 3:
			if phase == 1:
				actor_player.global_position.x += 180.0
				challenge.pulse.advance(challenge.definition.pulse_warning)
			elif phase == 2:
				challenge.pulse.advance(0.16)
			await process_frame
			challenge._update_hud()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/workshop_review/pulse_%d.png" % phase)
		quit()
		return
	if "--encirclement" in OS.get_cmdline_user_args():
		level.process_mode = Node.PROCESS_MODE_DISABLED
		var actor_player := level.get_node("Generated/Player") as PlayerController
		var observer := level.get_node("Generated/EncounterObservers/p2_flank_intro") as EncounterRuntimeObserver
		var challenge := observer.challenge
		actor_player.reset_at(Vector2(21600, 330))
		for actor: CombatTarget in observer._actors:
			challenge._commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
		observer._actors[0].global_position = Vector2(21520, 330)
		observer._actors[1].global_position = Vector2(21680, 330)
		challenge._advance_encirclement(1.0, observer._actors)
		actor_player.global_position.x += 180.0
		challenge._advance_encirclement(0.0, observer._actors)
		challenge._update_hud()
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(21700, 360)
		review_camera.make_current()
		await process_frame
		challenge._update_hud()
		await process_frame
		challenge._update_hud()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/encirclement.png")
		quit()
		return
	if "--collective-cover" in OS.get_cmdline_user_args():
		level.process_mode = Node.PROCESS_MODE_DISABLED
		var actor_player := level.get_node("Generated/Player") as PlayerController
		var observer := level.get_node("Generated/EncounterObservers/encounter_dispatch_ancom") as EncounterRuntimeObserver
		var challenge := observer.challenge
		var wounded := observer._actors[0]
		actor_player.reset_at(wounded.global_position - Vector2(100, 0))
		for actor: CombatTarget in observer._actors:
			challenge._commit(actor, ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
		wounded.receiver.receive_effect(actor_player.get_node("Identity"), EffectContext.offensive(), 10.0)
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(12700, 360)
		review_camera.make_current()
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		for step: int in 120:
			challenge._advance_retreat(1.0 / 60.0)
			challenge._update_hud()
			await physics_frame
			if step in [0, 20, 60, 119]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://reports/workshop_review/collective_cover_%d.png" % step)
		quit()
		return
	if "--mixed-arena" in OS.get_cmdline_user_args():
		level.process_mode = Node.PROCESS_MODE_DISABLED
		var actor_player := level.get_node("Generated/Player") as PlayerController
		actor_player.reset_at(Vector2(37900, 578))
		var observer := level.get_node("Generated/EncounterObservers/p3_final_coalition") as EncounterRuntimeObserver
		observer.challenge.advance(2.0)
		observer.challenge._stage_elapsed = 37.0
		observer.challenge.advance(0.2)
		observer.challenge._update_hud()
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(37850, 360)
		review_camera.make_current()
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/mixed_arena.png")
		quit()
		return
	if "--theft-effect" in OS.get_cmdline_user_args():
		level.process_mode = Node.PROCESS_MODE_DISABLED
		var actor_player := level.get_node("Generated/Player") as PlayerController
		var observer := level.get_node("Generated/EncounterObservers/encounter_storage_cache") as EncounterRuntimeObserver
		var actor := observer._actors[0]
		actor_player.reset_at(actor.global_position - Vector2(50, 0))
		observer.challenge._commit(actor, ConflictStateComponent.AggressorReason.FORCED_CONFISCATION)
		observer.challenge.try_contact(actor)
		var burst := actor_player.find_children("*", "TheftBurst", false, false)[0] as TheftBurst
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = actor.global_position + Vector2(-25, -65)
		review_camera.zoom = Vector2(2, 2)
		review_camera.make_current()
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		for step: int in 3:
			burst._process(0.1)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/workshop_review/theft_%d.png" % step)
		level.queue_free()
		review_camera.queue_free()
		await process_frame
		await create_timer(1.0).timeout
		quit()
		return
	if "--egoist-upper" in OS.get_cmdline_user_args() or "--egoist-stairs" in OS.get_cmdline_user_args():
		var stairs := "--egoist-stairs" in OS.get_cmdline_user_args()
		var actor_player := level.get_node("Generated/Player") as PlayerController
		var platform := level.get_node("Generated/Platforms/" + ("crew_return_a" if stairs else "dispatch_service_walkway")) as DebugPlatform
		platform.set_rule_enabled(true)
		actor_player.reset_at(Vector2(platform.global_position.x, platform.global_position.y - platform.size.y * 0.5 + platform.collision_surface_depth - 24.0))
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(platform.global_position.x, 360)
		review_camera.make_current()
		for frame: int in 240:
			await physics_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/egoist_stairs.png" if stairs else "res://reports/workshop_review/egoist_upper_pursuit.png")
		level.queue_free()
		review_camera.queue_free()
		await process_frame
		await create_timer(1.0).timeout
		quit()
		return
	if "--loot-arc" in OS.get_cmdline_user_args():
		var economy := level.get_node("Generated/Economy") as WorkshopEconomy
		var observer := level.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver
		var actor := observer._actors[0]
		actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
		actor.conflict_state.neutralize()
		var drop := economy.loot.drops["loot_" + String(actor.stable_id)] as DebugPickup
		level.process_mode = Node.PROCESS_MODE_DISABLED
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = actor.position + Vector2(25, -90)
		review_camera.zoom = Vector2(2, 2)
		review_camera.make_current()
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		for phase: String in ["launch", "apex", "landed"]:
			if phase != "launch":
				drop.advance_drop(drop.presentation.drop_arc_seconds * 0.5)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/workshop_review/loot_arc_%s.png" % phase)
		quit()
		return
	if "--humor-loot" in OS.get_cmdline_user_args() or "--pickup-expiry" in OS.get_cmdline_user_args():
		var economy := level.get_node("Generated/Economy") as WorkshopEconomy
		var index := 0
		var review_drops: Array[DebugPickup] = []
		for id: String in ["encounter_arrival_scout", "encounter_depot_patrol", "encounter_storage_cache"]:
			var actor := (level.get_node("Generated/EncounterObservers/" + id) as EncounterRuntimeObserver)._actors[0]
			actor.position = Vector2(640 + index * 160, 640)
			actor.conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
			actor.conflict_state.neutralize()
			economy.loot.release("loot_" + String(actor.stable_id))
			review_drops.append(economy.loot.drops["loot_" + String(actor.stable_id)])
			actor.visible = false
			index += 1
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(800, 620)
		review_camera.zoom = Vector2(2, 2)
		review_camera.make_current()
		level.process_mode = Node.PROCESS_MODE_DISABLED
		for drop: DebugPickup in review_drops:
			drop._visual_time = 0.45
			drop._update_collectible_visual()
		for frame: int in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/humorous_loot.png")
		if "--pickup-expiry" in OS.get_cmdline_user_args():
			for drop: DebugPickup in review_drops:
				drop.advance_lifetime(85.0)
				drop._visual_time = 0.0
				drop._update_collectible_visual()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/workshop_review/pickup_warning_bright.png")
			for drop: DebugPickup in review_drops:
				drop._visual_time = 0.3
				drop._update_collectible_visual()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/workshop_review/pickup_warning_dim.png")
			for drop: DebugPickup in review_drops:
				drop.advance_lifetime(10.0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/workshop_review/pickup_expired.png")
		quit()
		return
	if "--challenge-collective" in OS.get_cmdline_user_args() or "--challenge-raid" in OS.get_cmdline_user_args() or "--tactical-relay" in OS.get_cmdline_user_args():
		var relay := "--tactical-relay" in OS.get_cmdline_user_args()
		var collective := relay or "--challenge-collective" in OS.get_cmdline_user_args()
		var actor_player := level.get_node("Generated/Player") as PlayerController
		actor_player.reset_at(Vector2(6300 if collective else 9150, 640))
		var review_camera := Camera2D.new()
		root.add_child(review_camera)
		review_camera.position = Vector2(6680 if collective else 9530, 360)
		review_camera.make_current()
		for frame: int in 150:
			await physics_frame
		if relay:
			var observer := level.get_node("Generated/EncounterObservers/encounter_depot_patrol") as EncounterRuntimeObserver
			observer._actors[0].receiver.receive_effect(actor_player.get_node("Identity"), EffectContext.offensive(), 10.0)
			for frame: int in 100:
				await physics_frame
				if observer._actors[0].tactical_airborne:
					for apex_frame: int in 12:
						await physics_frame
					break
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/challenge_%s.png" % ("relay" if relay else ("collective" if collective else "raid")))
		quit()
		return
	if "--inventory" in OS.get_cmdline_user_args():
		var economy := level.get_node("Generated/Economy") as WorkshopEconomy
		economy.player.inventory.grant_once("review", {"trade_parts": 20, "production_key": 1, "communal_toothbrush": 10, "egoist_milk": 10, "social_contract": 20}, 40)
		economy.player_menu.open_menu()
		for frame: int in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/player_inventory.png")
		quit()
		return
	if "--loot" in OS.get_cmdline_user_args():
		var observer := level.get_node("Generated/EncounterObservers/encounter_arrival_scout") as EncounterRuntimeObserver
		observer._actors[0].conflict_state.commit_aggression(ConflictStateComponent.AggressorReason.ATTACK_COMMITTED)
		observer._actors[0].conflict_state.neutralize()
		var camera := Camera2D.new()
		root.add_child(camera)
		camera.position = Vector2(720, 390)
		camera.make_current()
		for frame: int in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/police_loot.png")
		quit()
		return
	if "--service" in OS.get_cmdline_user_args():
		var economy := level.get_node("Generated/Economy") as WorkshopEconomy
		economy.player.inventory.grant_once("review_service", {"service_parts": 10})
		economy.pay_machine("machine_production_feeder")
		for frame: int in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/mutualist_service.png")
		economy.close_service()
		level.queue_free()
		await process_frame
		await create_timer(1.0).timeout
		quit()
		return
	if "--economy" in OS.get_cmdline_user_args():
		var economy := level.get_node("Generated/Economy") as WorkshopEconomy
		economy.open_shop()
		if "--sale" in OS.get_cmdline_user_args():
			economy.player.inventory.grant_once("sale_preview", {"communal_toothbrush": 20})
			economy.select_sale("communal_toothbrush")
			economy.change_sale_quantity(6)
		for frame: int in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
		root.get_texture().get_image().save_png("res://reports/workshop_review/economy_shop.png")
		quit()
		return
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	level.process_mode = Node.PROCESS_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute("res://reports/workshop_review")
	var centers: Array = [750, 2200, 2900, 4100, 5700, 8300, 13000, 14850, 15900, 17000]
	if "--part-two" in OS.get_cmdline_user_args():
		centers = [20600, 21700, 23100, 24100, 24600, 26000, 27400]
	if "--paid-walkway" in OS.get_cmdline_user_args() or "--walkway-offer" in OS.get_cmdline_user_args():
		centers = [22700]
		var economy := level.get_node("Generated/Economy") as WorkshopEconomy
		var machine := level.get_node("Generated/RuleObjects/p2_maintenance_control") as RuleStateObject
		(level.get_node("Generated/Resources/p2_maintenance_parts") as DebugPickup)._on_body_entered(level.get_node("Generated/Player"))
		machine.interact()
		if "--walkway-offer" not in OS.get_cmdline_user_args():
			economy.confirm_service()
		(level.get_node("Generated/Player") as PlayerController).reset_at(Vector2(22530, 583))
	if "--underpass" in OS.get_cmdline_user_args():
		centers = [10450]
	if "--flank-exit" in OS.get_cmdline_user_args():
		centers = [26400]
	if "--pulse-exit" in OS.get_cmdline_user_args():
		centers = [35150, 35700]
	if "--p1-returns" in OS.get_cmdline_user_args():
		centers = [8260, 14400, 16000, 19600]
		for id: String in ["encounter_depot_patrol", "encounter_dispatch_ancom"]:
			(level.get_node("Generated/EncounterObservers/" + id) as EncounterRuntimeObserver).restore_runtime_state({"resolved": true})
	if "--lift-landings" in OS.get_cmdline_user_args():
		centers = [4250, 9630, 14400, 19700]
	if "--coalition-exit" in OS.get_cmdline_user_args():
		centers = [38600, 39180]
	if "--part-three" in OS.get_cmdline_user_args():
		centers = [28900, 30300, 31800, 32700, 33300, 34900, 36200, 37900, 39600]
	if "--opening" in OS.get_cmdline_user_args():
		centers = [750, 1750, 2950, 3550]
	if "--collective-layout" in OS.get_cmdline_user_args():
		centers = [6840, 12850, 19200]
	if "--crew-return" in OS.get_cmdline_user_args():
		centers = [17800]
	for center: int in centers:
		camera.position = Vector2(center, 360)
		camera.reset_smoothing()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/workshop_review/zone_%d.png" % center)
	quit()
