class_name CampaignFlowController
extends Node2D

@export var world_definition: WorldDefinition
@export var background_texture: Texture2D
@export var development_level: PackedScene

var _progress: CampaignProgressState
var _mission: LevelBuilder
var _menu: CanvasLayer
var _status: Label
var _first_button: Button


func _ready() -> void:
	if world_definition == null or not world_definition.validation_errors().is_empty():
		push_error("WorldDefinition inválido")
		return
	_progress = CampaignProgressStore.load_state()
	if _progress == null or _progress.world_id != world_definition.world_id:
		_progress = CampaignProgressState.new()
		_progress.world_id = world_definition.world_id
		_progress.active_mission_id = world_definition.missions[0].mission_id
	_progress.reconcile(world_definition)
	_build_menu()
	_show_menu()


func _build_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.name = "CampaignMenu"
	add_child(_menu)
	var backdrop := Control.new()
	backdrop.theme = preload("res://assets/ui/game_theme.tres")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(backdrop)
	if background_texture != null:
		var art := TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.texture = background_texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(art)
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color("0d1022b8")
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(scrim)
	var card := PanelContainer.new()
	card.position = Vector2(160.0, 40.0)
	card.size = Vector2(960.0, 640.0)
	backdrop.add_child(card)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(660.0, 450.0)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 14)
	card.add_child(panel)
	var title := Label.new()
	title.text = "ANARCHYBALL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("ffdb55"))
	panel.add_child(title)
	var portrait := TextureRect.new()
	portrait.name = "HeroPortrait"
	portrait.custom_minimum_size = Vector2(0, 100)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame := AtlasTexture.new()
	frame.atlas = preload("res://assets/art/actors/balls/world_0/runtime/anarchy_ball_keyposes.png")
	frame.region = Rect2(0, 0, 96, 96)
	portrait.texture = frame
	panel.add_child(portrait)
	var subtitle := Label.new()
	subtitle.text = world_definition.display_name
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("76e6ff"))
	panel.add_child(subtitle)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(620.0, 56.0)
	panel.add_child(_status)
	if development_level != null:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(row)
		for resume: bool in [false, true]:
			var button := Button.new()
			button.text = "CONTINUAR TALLER" if resume else "NUEVO TALLER"
			button.custom_minimum_size = Vector2(310, 48)
			if _first_button == null:
				_first_button = button
			button.pressed.connect(_start_development_level.bind(resume))
			row.add_child(button)
	var new_button := Button.new()
	new_button.text = "NUEVA MISIÓN"
	new_button.custom_minimum_size = Vector2(320.0, 48.0)
	new_button.pressed.connect(_start_active_mission.bind(false))
	panel.add_child(new_button)
	var continue_button := Button.new()
	continue_button.text = "CONTINUAR CHECKPOINT"
	continue_button.custom_minimum_size = Vector2(320.0, 48.0)
	continue_button.pressed.connect(_start_active_mission.bind(true))
	panel.add_child(continue_button)
	var controls := Label.new()
	controls.text = "FLECHAS / D-PAD: ELEGIR   ·   ENTER / A: ACEPTAR"
	controls.add_theme_font_size_override("font_size", 12)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(controls)
	if _first_button == null:
		_first_button = new_button


func _show_menu() -> void:
	_menu.visible = true
	_first_button.grab_focus()
	var mission := world_definition.mission_by_id(_progress.active_mission_id)
	_status.text = "%s\nCompletada: %s" % [mission.display_name, "sí" if mission.mission_id in _progress.completed_mission_ids else "no"]


func _start_active_mission(resume: bool) -> void:
	var definition := world_definition.mission_by_id(_progress.active_mission_id)
	if definition == null:
		return
	_menu.visible = false
	_mission = definition.mission_scene.instantiate() as LevelBuilder
	_mission.campaign_mode = true
	_mission.resume_from_checkpoint = resume
	_mission.level_completed.connect(_on_level_completed)
	_mission.return_to_campaign_requested.connect(_on_return_requested)
	add_child(_mission)


func _on_level_completed(mission_id: StringName) -> void:
	_progress.complete(mission_id, world_definition)
	CampaignProgressStore.save(_progress)


func _start_development_level(resume: bool) -> void:
	if development_level == null or _mission != null:
		return
	_menu.visible = false
	_mission = development_level.instantiate() as LevelBuilder
	_mission.campaign_mode = true
	_mission.resume_from_checkpoint = resume
	# A development slice has its own checkpoint; never advances the legacy campaign.
	_mission.return_to_campaign_requested.connect(_on_return_requested)
	add_child(_mission)


func _on_return_requested(_mission_id: StringName) -> void:
	if _mission != null:
		_mission.queue_free()
		_mission = null
	_show_menu()
