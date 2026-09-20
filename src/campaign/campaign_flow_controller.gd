class_name CampaignFlowController
extends Node2D

@export var world_definition: WorldDefinition

var _progress: CampaignProgressState
var _mission: LevelBuilder
var _menu: CanvasLayer
var _status: Label


func _ready() -> void:
	if world_definition == null or not world_definition.validation_errors().is_empty():
		push_error("WorldDefinition inválido")
		return
	_progress = CampaignProgressStore.load_state()
	if _progress == null or _progress.world_id != world_definition.world_id:
		_progress = CampaignProgressState.new()
		_progress.world_id = world_definition.world_id
		_progress.active_mission_id = world_definition.missions[0].mission_id
	_build_menu()
	_show_menu()


func _build_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.name = "CampaignMenu"
	add_child(_menu)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("101527")
	_menu.add_child(backdrop)
	var panel := VBoxContainer.new()
	panel.position = Vector2(310.0, 135.0)
	panel.size = Vector2(660.0, 450.0)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 18)
	backdrop.add_child(panel)
	var title := Label.new()
	title.text = "ANARCHYBALL · WORLD 0"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	panel.add_child(title)
	var subtitle := Label.new()
	subtitle.text = world_definition.display_name
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	panel.add_child(subtitle)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(620.0, 85.0)
	panel.add_child(_status)
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
	controls.text = "Teclado y gamepad disponibles · progreso local versionado"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(controls)
	new_button.grab_focus()


func _show_menu() -> void:
	_menu.visible = true
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


func _on_return_requested(_mission_id: StringName) -> void:
	if _mission != null:
		_mission.queue_free()
		_mission = null
	_show_menu()
