extends SceneTree

const CELL_SIZE := Vector2i(96, 96)
const FRAME_COUNT: int = 8
const MAX_DRAW_SIZE := Vector2i(88, 88)
const BASELINE_Y: int = 90
const CANNON_SOURCE := "res://assets/art/art_bible/concepts/anarchy_ball_front_cannon_overlay_v1.png"
const CANNON_OUTPUT := "res://assets/art/vfx/world_0/anarchy_front_cannon.png"
const ROBBER_POLISHED_SOURCE := "res://assets/art/actors/balls/world_0/runtime/robber_ball_animation_v4.png"
const ROBBER_POLISHED_OUTPUT := "res://assets/art/actors/balls/world_0/runtime/robber_ball_animation_v5.png"
const JOBS: Array[Dictionary] = [
	{
		"source": "res://assets/art/art_bible/concepts/anarchy_ball_ancap_surface_concept_v2.png",
		"output": "res://assets/art/actors/balls/world_0/runtime/anarchy_ball_keyposes.png",
		"animation_output": "res://assets/art/actors/balls/world_0/runtime/anarchy_ball_animation_draft.png",
		"surrender_frame": 7,
		"trim_action_trail": true,
		"detect_pose_ranges": true,
		"action_body_frame": 2,
		"animation_frames": [0, 0, 4, 0, 7, 1, 7, 7],
	},
	{
		"source": "res://assets/art/actors/balls/world_0/concepts/merchant_ball_concept.png",
		"output": "res://assets/art/actors/balls/world_0/runtime/merchant_ball_keyposes.png",
		"animation_output": "res://assets/art/actors/balls/world_0/runtime/merchant_ball_animation_draft.png",
		"surrender_frame": 5,
		"animation_frames": [0, 0, 3, 0, 7, 4, 5, 5],
	},
	{
		"source": "res://assets/art/actors/balls/world_0/concepts/robber_ball_concept.png",
		"output": "res://assets/art/actors/balls/world_0/runtime/robber_ball_keyposes.png",
		"animation_output": "res://assets/art/actors/balls/world_0/runtime/robber_ball_animation_draft.png",
		"surrender_frame": 6,
		"animation_frames": [0, 0, 2, 0, 5, 3, 6, 7],
	},
	{
		"source": "res://assets/art/actors/balls/world_0/concepts/egoist_ball_concept_v2.png",
		"output": "res://assets/art/actors/balls/world_0/runtime/egoist_ball_keyposes.png",
		"animation_output": "res://assets/art/actors/balls/world_0/runtime/egoist_ball_animation_draft.png",
		"surrender_frame": 7,
		"animation_frames": [0, 0, 4, 0, 7, 1, 7, 7],
	},
	{
		"source": "res://assets/art/actors/balls/world_0/concepts/mutualist_ball_concept_v4.png",
		"output": "res://assets/art/actors/balls/world_0/runtime/mutualist_ball_keyposes.png",
		"animation_output": "res://assets/art/actors/balls/world_0/runtime/mutualist_ball_animation_draft.png",
		"surrender_frame": 6,
		"animation_frames": [0, 0, 4, 0, 6, 1, 6, 7],
	},
	{
		"source": "res://assets/art/actors/balls/world_0/concepts/police_ball_leviathan_concept_v2.png",
		"output": "res://assets/art/actors/balls/world_0/runtime/occupancy_enforcer_ball_keyposes.png",
		"animation_output": "res://assets/art/actors/balls/world_0/runtime/occupancy_enforcer_ball_animation_draft.png",
		"surrender_frame": 6,
		"animation_frames": [0, 0, 3, 0, 5, 2, 6, 7],
	},
	{
		"source": "res://assets/art/actors/balls/world_0/concepts/ancom_ball_concept_v2.png",
		"output": "res://assets/art/actors/balls/world_0/runtime/ancom_ball_keyposes.png",
		"animation_output": "res://assets/art/actors/balls/world_0/runtime/ancom_ball_animation_draft.png",
		"surrender_frame": 6,
		"pose_ranges": [
			Rect2i(11, 0, 229, 724), Rect2i(260, 0, 245, 724),
			Rect2i(505, 0, 267, 724), Rect2i(790, 0, 320, 724),
			Rect2i(1128, 0, 255, 724), Rect2i(1402, 0, 237, 724),
			Rect2i(1668, 0, 232, 724), Rect2i(1931, 0, 236, 724),
		],
		"animation_frames": [0, 1, 2, 3, 4, 5, 6, 7],
	},
]


func _init() -> void:
	for job: Dictionary in JOBS:
		_build_atlas(
			String(job["source"]),
			String(job["output"]),
			bool(job.get("trim_action_trail", false)),
			bool(job.get("detect_pose_ranges", false)),
			int(job.get("action_body_frame", -1)),
			job.get("pose_ranges", []) as Array
		)
		_build_animation_draft(
			String(job["output"]),
			String(job["animation_output"]),
			job["animation_frames"] as Array
		)
	_build_overlay(CANNON_SOURCE, CANNON_OUTPUT, Vector2i(44, 34))
	_replace_action_row(ROBBER_POLISHED_SOURCE, ROBBER_POLISHED_OUTPUT)
	quit()


func _build_atlas(
	source_path: String,
	output_path: String,
	trim_action_trail: bool,
	detect_pose_ranges: bool,
	action_body_frame: int,
	explicit_pose_ranges: Array
) -> void:
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Unable to load concept source: %s" % source_path)
		return
	var atlas := Image.create(CELL_SIZE.x * FRAME_COUNT, CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var source_ranges: Array[Rect2i] = []
	if not explicit_pose_ranges.is_empty():
		for pose_range: Variant in explicit_pose_ranges:
			source_ranges.append(pose_range as Rect2i)
	elif detect_pose_ranges:
		source_ranges = _detect_frame_ranges(source)
		if source_ranges.size() != FRAME_COUNT:
			push_error("Expected %d separated poses in %s, found %d: %s" % [FRAME_COUNT, source_path, source_ranges.size(), source_ranges])
			return
	else:
		for frame_index: int in range(FRAME_COUNT):
			var x_start := roundi(float(frame_index * source.get_width()) / float(FRAME_COUNT))
			var x_end := roundi(float((frame_index + 1) * source.get_width()) / float(FRAME_COUNT))
			source_ranges.append(Rect2i(x_start, 0, x_end - x_start, source.get_height()))
	var body_widths: Array[int] = []
	for frame_index: int in range(FRAME_COUNT):
		if frame_index != 6:
			body_widths.append((source_ranges[frame_index] as Rect2i).size.x)
	body_widths.sort()
	var reference_body_width := body_widths[body_widths.size() / 2]
	var trimmed_frames: Array[Image] = []
	var largest_source := Vector2i.ONE
	for frame_index: int in range(FRAME_COUNT):
		var source_rect := source_ranges[frame_index] as Rect2i
		if trim_action_trail and frame_index == 6:
			# El proyectil es una entidad separada en runtime. Conservamos cuerpo y
			# emisor, pero no la estela conceptual que alteraba la escala y se cortaba.
			source_rect.size.x = mini(source_rect.size.x, reference_body_width)
		var segment := source.get_region(source_rect)
		_clear_edge_background(segment)
		_clear_small_edge_fragments(segment)
		_clear_small_components(segment)
		var used_rect := segment.get_used_rect()
		if used_rect.size == Vector2i.ZERO:
			push_error("Empty frame %d in %s" % [frame_index, source_path])
			continue
		var trimmed := segment.get_region(used_rect)
		trimmed_frames.append(trimmed)
		largest_source.x = maxi(largest_source.x, trimmed.get_width())
		largest_source.y = maxi(largest_source.y, trimmed.get_height())
	var shared_scale := minf(
		float(MAX_DRAW_SIZE.x) / float(largest_source.x),
		float(MAX_DRAW_SIZE.y) / float(largest_source.y)
	)
	for frame_index: int in range(trimmed_frames.size()):
		var trimmed := trimmed_frames[frame_index]
		var target_size := Vector2i(
			maxi(1, roundi(float(trimmed.get_width()) * shared_scale)),
			maxi(1, roundi(float(trimmed.get_height()) * shared_scale))
		)
		trimmed.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
		var destination := Vector2i(
			frame_index * CELL_SIZE.x + (CELL_SIZE.x - target_size.x) / 2,
			BASELINE_Y - target_size.y
		)
		atlas.blit_rect(trimmed, Rect2i(Vector2i.ZERO, target_size), destination)
	if action_body_frame >= 0:
		atlas.blit_rect(
			atlas,
			Rect2i(action_body_frame * CELL_SIZE.x, 0, CELL_SIZE.x, CELL_SIZE.y),
			Vector2i(6 * CELL_SIZE.x, 0)
		)
	var absolute_output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	var error := atlas.save_png(absolute_output)
	if error != OK:
		push_error("Unable to save atlas %s: %s" % [output_path, error_string(error)])
	else:
		print("BALL ATLAS: %s" % output_path)


func _build_overlay(source_path: String, output_path: String, max_size: Vector2i) -> void:
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Unable to load overlay source: %s" % source_path)
		return
	_clear_edge_background(source)
	_clear_small_components(source)
	var used_rect := source.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_error("Empty overlay source: %s" % source_path)
		return
	var trimmed := source.get_region(used_rect)
	var scale_factor := minf(
		float(max_size.x) / float(trimmed.get_width()),
		float(max_size.y) / float(trimmed.get_height())
	)
	var target_size := Vector2i(
		maxi(1, roundi(trimmed.get_width() * scale_factor)),
		maxi(1, roundi(trimmed.get_height() * scale_factor))
	)
	trimmed.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var absolute_output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	var error := trimmed.save_png(absolute_output)
	if error != OK:
		push_error("Unable to save overlay %s: %s" % [output_path, error_string(error)])
	else:
		print("BALL OVERLAY: %s" % output_path)


func _detect_frame_ranges(source: Image) -> Array[Rect2i]:
	var ranges: Array[Rect2i] = []
	var range_start := -1
	for x: int in range(source.get_width() + 1):
		var active := x < source.get_width() and _column_has_foreground(source, x)
		if active and range_start < 0:
			range_start = x
		elif not active and range_start >= 0:
			var width := x - range_start
			# Algunos conceptos contienen columnas aisladas de antialiasing sobre el
			# fondo. No representan poses y no deben alterar el conteo de frames.
			if width > 4:
				ranges.append(Rect2i(range_start, 0, width, source.get_height()))
			range_start = -1
	return ranges


func _column_has_foreground(source: Image, x: int) -> bool:
	for y: int in range(source.get_height()):
		var color := source.get_pixel(x, y)
		if color.a >= 0.01 and maxf(color.r, maxf(color.g, color.b)) > 0.035:
			return true
	return false


func _clear_edge_background(image: Image) -> void:
	# Concept sheets arrived over opaque black. Only erase near-black pixels that
	# are connected to a frame edge, preserving the ball's enclosed dark fields.
	var pending: Array[Vector2i] = []
	var visited: Dictionary = {}
	for x: int in range(image.get_width()):
		pending.append(Vector2i(x, 0))
		pending.append(Vector2i(x, image.get_height() - 1))
	for y: int in range(image.get_height()):
		pending.append(Vector2i(0, y))
		pending.append(Vector2i(image.get_width() - 1, y))
	var cursor: int = 0
	while cursor < pending.size():
		var point := pending[cursor]
		cursor += 1
		if point.x < 0 or point.y < 0 or point.x >= image.get_width() or point.y >= image.get_height():
			continue
		var key := point.y * image.get_width() + point.x
		if visited.has(key):
			continue
		visited[key] = true
		var color := image.get_pixelv(point)
		if color.a < 0.01 or maxf(color.r, maxf(color.g, color.b)) <= 0.035:
			image.set_pixelv(point, Color.TRANSPARENT)
			pending.append(point + Vector2i.LEFT)
			pending.append(point + Vector2i.RIGHT)
			pending.append(point + Vector2i.UP)
			pending.append(point + Vector2i.DOWN)


func _clear_small_edge_fragments(image: Image) -> void:
	# Equal-width concept slices can contain a thin piece of the neighbouring
	# pose. Remove only small opaque components connected to a vertical edge.
	var visited: Dictionary = {}
	for y: int in range(image.get_height()):
		for start_x: int in [0, image.get_width() - 1]:
			var start := Vector2i(start_x, y)
			var start_key := start.y * image.get_width() + start.x
			if visited.has(start_key) or image.get_pixelv(start).a < 0.01:
				continue
			var component: Array[Vector2i] = []
			var pending: Array[Vector2i] = [start]
			var cursor: int = 0
			while cursor < pending.size():
				var point := pending[cursor]
				cursor += 1
				if point.x < 0 or point.y < 0 or point.x >= image.get_width() or point.y >= image.get_height():
					continue
				var key := point.y * image.get_width() + point.x
				if visited.has(key) or image.get_pixelv(point).a < 0.01:
					continue
				visited[key] = true
				component.append(point)
				pending.append(point + Vector2i.LEFT)
				pending.append(point + Vector2i.RIGHT)
				pending.append(point + Vector2i.UP)
				pending.append(point + Vector2i.DOWN)
			if component.size() < image.get_width() * image.get_height() * 0.08:
				for point: Vector2i in component:
					image.set_pixelv(point, Color.TRANSPARENT)


func _clear_small_components(image: Image) -> void:
	var visited: Dictionary = {}
	var minimum_area := maxi(12, roundi(image.get_width() * image.get_height() * 0.0015))
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var start := Vector2i(x, y)
			var start_key := y * image.get_width() + x
			if visited.has(start_key) or image.get_pixelv(start).a < 0.01:
				continue
			var component: Array[Vector2i] = []
			var pending: Array[Vector2i] = [start]
			var cursor: int = 0
			while cursor < pending.size():
				var point := pending[cursor]
				cursor += 1
				if point.x < 0 or point.y < 0 or point.x >= image.get_width() or point.y >= image.get_height():
					continue
				var key := point.y * image.get_width() + point.x
				if visited.has(key) or image.get_pixelv(point).a < 0.01:
					continue
				visited[key] = true
				component.append(point)
				pending.append(point + Vector2i.LEFT)
				pending.append(point + Vector2i.RIGHT)
				pending.append(point + Vector2i.UP)
				pending.append(point + Vector2i.DOWN)
			if component.size() < minimum_area:
				for point: Vector2i in component:
					image.set_pixelv(point, Color.TRANSPARENT)


func _build_animation_draft(keypose_path: String, output_path: String, state_frames: Array) -> void:
	var keyposes := Image.load_from_file(keypose_path)
	if keyposes == null or keyposes.is_empty():
		push_error("Unable to load keypose atlas: %s" % keypose_path)
		return
	var atlas := Image.create(CELL_SIZE.x * 8, CELL_SIZE.y * 8, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	# Cada estado usa ocho celdas y, además de cambiar de keypose cuando existe,
	# aplica una silueta temporal propia. Así ningún estado queda como una pose
	# estática repetida mientras las futuras balls siguen el mismo contrato.
	if state_frames.size() != 8:
		push_error("Expected one source frame per animation state in %s" % keypose_path)
		return
	for row: int in range(state_frames.size()):
		for column: int in range(FRAME_COUNT):
			var source_frame := int(state_frames[row])
			var source_rect := Rect2i(source_frame * CELL_SIZE.x, 0, CELL_SIZE.x, CELL_SIZE.y)
			var source_cell := keyposes.get_region(source_rect)
			_blit_animated_cell(atlas, source_cell, row, column)
	var absolute_output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	var error := atlas.save_png(absolute_output)
	if error != OK:
		push_error("Unable to save animation draft %s: %s" % [output_path, error_string(error)])
	else:
		print("BALL ANIMATION DRAFT: %s" % output_path)


func _replace_action_row(source_path: String, output_path: String) -> void:
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Unable to load polished animation source: %s" % source_path)
		return
	var neutral_cell := source.get_region(Rect2i(0, 0, CELL_SIZE.x, CELL_SIZE.y))
	source.fill_rect(Rect2i(0, 3 * CELL_SIZE.y, source.get_width(), CELL_SIZE.y), Color.TRANSPARENT)
	for column: int in range(FRAME_COUNT):
		_blit_animated_cell(source, neutral_cell, 3, column)
	var absolute_output := ProjectSettings.globalize_path(output_path)
	var error := source.save_png(absolute_output)
	if error != OK:
		push_error("Unable to save corrected polished animation %s: %s" % [output_path, error_string(error)])
	else:
		print("BALL ACTION ROW: %s" % output_path)


func _blit_animated_cell(atlas: Image, source_cell: Image, row: int, column: int) -> void:
	var used_rect := source_cell.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return
	var trimmed := source_cell.get_region(used_rect)
	var transform := _animation_transform(row, column)
	var scale_xy := transform["scale"] as Vector2
	var target_size := Vector2i(
		maxi(1, roundi(float(trimmed.get_width()) * scale_xy.x)),
		maxi(1, roundi(float(trimmed.get_height()) * scale_xy.y))
	)
	trimmed.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var offset := transform["offset"] as Vector2i
	var local_x := clampi(
		(CELL_SIZE.x - target_size.x) / 2 + offset.x,
		2,
		CELL_SIZE.x - target_size.x - 2
	)
	var local_y := clampi(
		BASELINE_Y - target_size.y + offset.y,
		2,
		CELL_SIZE.y - target_size.y - 2
	)
	var destination := Vector2i(column * CELL_SIZE.x + local_x, row * CELL_SIZE.y + local_y)
	atlas.blit_rect(trimmed, Rect2i(Vector2i.ZERO, target_size), destination)


func _animation_transform(row: int, column: int) -> Dictionary:
	var phase := column % FRAME_COUNT
	match row:
		0: # idle: respiración lenta y asentamiento vertical
			return {"scale": Vector2(1.0 + [0.0, 0.01, 0.02, 0.01, 0.0, -0.01, -0.02, -0.01][phase], 1.0 + [0.0, -0.01, -0.02, -0.01, 0.0, 0.01, 0.02, 0.01][phase]), "offset": Vector2i(0, [0, 1, 2, 1, 0, -1, -2, -1][phase])}
		1: # move: rodamiento con squash y avance lateral
			return {"scale": Vector2(1.0 + [0.02, 0.0, -0.02, 0.0, 0.02, 0.0, -0.02, 0.0][phase], 1.0 + [-0.02, 0.0, 0.02, 0.0, -0.02, 0.0, 0.02, 0.0][phase]), "offset": Vector2i([-2, -1, 0, 1, 2, 1, 0, -1][phase], [1, 0, -2, 0, 1, 0, -2, 0][phase])}
		2: # jump: anticipación, ascenso, ápice y aterrizaje
			return {"scale": Vector2(1.0 + [0.04, 0.02, 0.0, -0.02, -0.02, 0.0, 0.02, 0.04][phase], 1.0 + [-0.04, -0.02, 0.0, 0.03, 0.03, 0.0, -0.02, -0.04][phase]), "offset": Vector2i(0, [2, -1, -4, -7, -7, -4, -1, 2][phase])}
		3: # action: anticipación y recoil
			return {"scale": Vector2(1.0 + [-0.03, -0.01, 0.03, 0.05, 0.02, 0.0, -0.02, -0.03][phase], 1.0 + [0.03, 0.01, -0.02, -0.04, -0.01, 0.0, 0.02, 0.03][phase]), "offset": Vector2i([-2, -1, 1, 3, 2, 0, -1, -2][phase], [1, 0, 0, 1, 0, 0, 1, 1][phase])}
		4: # hurt: sacudida que se amortigua
			return {"scale": Vector2(1.0 + [0.04, -0.03, 0.03, -0.02, 0.01, -0.01, 0.0, 0.0][phase], 1.0 + [-0.04, 0.03, -0.03, 0.02, -0.01, 0.01, 0.0, 0.0][phase]), "offset": Vector2i([-4, 4, -3, 3, -2, 2, -1, 0][phase], [0, 1, 0, 1, 0, 1, 0, 0][phase])}
		5: # threatening: pulso de anticipación
			return {"scale": Vector2.ONE * (1.0 + [0.0, 0.015, 0.03, 0.015, 0.0, -0.01, -0.02, -0.01][phase]), "offset": Vector2i(0, [0, -1, -2, -1, 0, 1, 2, 1][phase])}
		6: # surrendering: descenso y temblor contenido
			return {"scale": Vector2(1.0 + [0.0, -0.01, 0.0, -0.01, 0.0, -0.01, 0.0, -0.01][phase], 1.0 + [0.0, 0.01, 0.02, 0.03, 0.04, 0.03, 0.02, 0.01][phase]), "offset": Vector2i([-1, 0, 1, 0, -1, 0, 1, 0][phase], [0, 1, 2, 3, 4, 3, 2, 1][phase])}
		_: # neutralized: asentamiento final, todavía legible y no congelado
			return {"scale": Vector2(1.0 + [0.0, -0.01, -0.02, -0.01, 0.0, 0.005, 0.01, 0.005][phase], 1.0 + [0.0, 0.01, 0.02, 0.01, 0.0, -0.005, -0.01, -0.005][phase]), "offset": Vector2i(0, [0, 1, 2, 3, 3, 2, 1, 0][phase])}
