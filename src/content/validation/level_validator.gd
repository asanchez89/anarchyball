class_name LevelValidator
extends RefCounted

const REQUIRED_FIELDS: PackedStringArray = [
	"schema_version",
	"level_id",
	"player_spawn",
	"exit",
	"bounds",
	"movement_profile_path",
	"class_loadout_id",
	"ideology_rule_ids",
	"platforms",
	"encounters",
	"resources",
	"sections",
]
const RESOURCE_OWNERSHIP: PackedStringArray = [
	"unowned_collectible",
	"mission_reward",
	"returned_property",
	"permitted_salvage",
	"class_generated_supply",
]


static func validate(spec: LevelSpec, registry: ContentRegistry) -> LevelValidationResult:
	var result := LevelValidationResult.new(spec.source_path if spec != null else "<missing>")
	if spec == null:
		result.add_error(&"missing_spec", "root", "LevelSpec es nulo")
		return result
	for field: String in REQUIRED_FIELDS:
		if not spec.data.has(field):
			result.add_error(&"missing_field", field, "campo obligatorio ausente")
	if not result.is_valid():
		return result

	_validate_identity(spec.data.get("level_id"), "level_id", result)
	if int(spec.data.get("schema_version", -1)) != LevelSpec.CURRENT_SCHEMA_VERSION:
		result.add_error(&"unsupported_schema", "schema_version", "se esperaba v%d" % LevelSpec.CURRENT_SCHEMA_VERSION)
	_validate_vector(spec.data.get("player_spawn"), "player_spawn", result)
	_validate_vector(spec.data.get("exit"), "exit", result)
	_validate_bounds(spec.data.get("bounds"), result)
	_validate_point_in_bounds(spec.data.get("player_spawn"), spec.data.get("bounds"), "player_spawn", result)
	_validate_point_in_bounds(spec.data.get("exit"), spec.data.get("bounds"), "exit", result)
	_validate_reference(
		registry,
		ContentRegistry.Kind.CLASS_LOADOUT,
		spec.data.get("class_loadout_id"),
		"class_loadout_id",
		result
	)
	_validate_ideology_rules(spec.data.get("ideology_rule_ids"), registry, result)
	_validate_platforms(spec.data.get("platforms"), result)
	_validate_encounters(spec.data.get("encounters"), registry, result)
	_validate_resources(spec.data.get("resources"), result)
	_validate_mission_rewards_on_base_route(spec, result)
	_validate_sections(spec.data.get("sections"), result)
	_validate_checkpoints(spec.data.get("checkpoints", []), result)
	_validate_gates(spec.data.get("gates", []), registry, spec.data.get("ideology_rule_ids"), result)
	_validate_movement_and_reachability(spec, result)
	return result


static func _validate_identity(value: Variant, path: String, result: LevelValidationResult) -> void:
	var content_id := StringName(String(value))
	if not ContentId.is_valid(content_id):
		result.add_error(&"invalid_id", path, "'%s' debe ser snake_case estable" % value)


static func _validate_vector(value: Variant, path: String, result: LevelValidationResult) -> void:
	if not value is Dictionary:
		result.add_error(&"invalid_type", path, "se esperaba objeto con x/y")
		return
	var vector := value as Dictionary
	if not vector.has("x") or not vector.has("y"):
		result.add_error(&"missing_field", path, "faltan x/y")


static func _validate_bounds(value: Variant, result: LevelValidationResult) -> void:
	if not value is Dictionary:
		result.add_error(&"invalid_type", "bounds", "se esperaba objeto con width/height")
		return
	var bounds := value as Dictionary
	if float(bounds.get("width", 0.0)) <= 0.0 or float(bounds.get("height", 0.0)) <= 0.0:
		result.add_error(&"invalid_bounds", "bounds", "width y height deben ser positivos")


static func _validate_point_in_bounds(point_value: Variant, bounds_value: Variant, path: String, result: LevelValidationResult) -> void:
	if not point_value is Dictionary or not bounds_value is Dictionary:
		return
	var point := point_value as Dictionary
	var bounds := bounds_value as Dictionary
	var x := float(point.get("x", -1.0))
	var y := float(point.get("y", -1.0))
	if x < 0.0 or y < 0.0 or x > float(bounds.get("width", 0.0)) or y > float(bounds.get("height", 0.0)):
		result.add_error(&"point_out_of_bounds", path, "la posición debe estar dentro de bounds")


static func _validate_reference(
	registry: ContentRegistry,
	kind: ContentRegistry.Kind,
	value: Variant,
	path: String,
	result: LevelValidationResult
) -> void:
	var content_id := StringName(String(value))
	_validate_identity(content_id, path, result)
	if registry == null or not registry.has(kind, content_id):
		result.add_error(&"unknown_reference", path, "ID no registrado '%s'" % content_id)


static func _validate_ideology_rules(value: Variant, registry: ContentRegistry, result: LevelValidationResult) -> void:
	if not value is Array:
		result.add_error(&"invalid_type", "ideology_rule_ids", "se esperaba array")
		return
	var rules := value as Array
	if rules.size() > 1:
		result.add_error(&"too_many_primary_rules", "ideology_rule_ids", "el borrador admite una regla primaria")
	for index: int in rules.size():
		_validate_reference(registry, ContentRegistry.Kind.IDEOLOGY_RULE, rules[index], "ideology_rule_ids[%d]" % index, result)
		var definition := registry.get_definition(ContentRegistry.Kind.IDEOLOGY_RULE, StringName(String(rules[index]))) as IdeologyRuleDefinition
		if definition != null and not definition.is_structurally_valid():
			result.add_error(&"invalid_ideology_rule", "ideology_rule_ids[%d]" % index, "la definición está incompleta")


static func _validate_platforms(value: Variant, result: LevelValidationResult) -> void:
	if not value is Array or (value as Array).is_empty():
		result.add_error(&"missing_platforms", "platforms", "se requiere al menos una plataforma")
		return
	for index: int in (value as Array).size():
		var path := "platforms[%d]" % index
		var platform: Variant = (value as Array)[index]
		if not platform is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var data := platform as Dictionary
		_validate_identity(data.get("id", ""), path + ".id", result)
		_validate_vector(data, path, result)
		if float(data.get("width", 0.0)) <= 0.0 or float(data.get("height", 0.0)) <= 0.0:
			result.add_error(&"invalid_geometry", path, "width/height deben ser positivos")
		if not data.get("route_tags", []) is Array:
			result.add_error(&"invalid_type", path + ".route_tags", "se esperaba array")
			continue
		var route_tags := data.get("route_tags", []) as Array
		if not bool(data.get("required", true)) and route_tags.is_empty():
			result.add_error(&"missing_route_tag", path + ".route_tags", "una ruta opcional debe declarar tags")
		for tag_index: int in route_tags.size():
			_validate_identity(route_tags[tag_index], path + ".route_tags[%d]" % tag_index, result)


static func _validate_encounters(value: Variant, registry: ContentRegistry, result: LevelValidationResult) -> void:
	if not value is Array:
		result.add_error(&"invalid_type", "encounters", "se esperaba array")
		return
	for index: int in (value as Array).size():
		var encounter: Variant = (value as Array)[index]
		var path := "encounters[%d]" % index
		if not encounter is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var encounter_data := encounter as Dictionary
		_validate_identity(encounter_data.get("id", ""), path + ".id", result)
		_validate_vector(encounter_data, path, result)
		var definition_id: Variant = encounter_data.get("definition_id", "")
		_validate_reference(registry, ContentRegistry.Kind.ENCOUNTER_DEFINITION, definition_id, path + ".definition_id", result)
		var definition := registry.get_definition(ContentRegistry.Kind.ENCOUNTER_DEFINITION, StringName(String(definition_id))) as EncounterDefinition
		if definition == null:
			continue
		if not definition.is_structurally_valid():
			result.add_error(&"invalid_encounter", path + ".definition_id", "encounter sin objetivo, éxito o resolución")
		if not definition.protected_archetype_id.is_empty() and not registry.has(ContentRegistry.Kind.ENEMY_ARCHETYPE, definition.protected_archetype_id):
			result.add_error(&"unknown_reference", path + ".definition_id", "Actor protegido no registrado '%s'" % definition.protected_archetype_id)
		for enemy_id: StringName in definition.enemy_archetype_ids:
			if not registry.has(ContentRegistry.Kind.ENEMY_ARCHETYPE, enemy_id):
				result.add_error(&"unknown_reference", path + ".definition_id", "EnemyArchetype no registrado '%s'" % enemy_id)
				continue
			var archetype := registry.get_definition(ContentRegistry.Kind.ENEMY_ARCHETYPE, enemy_id) as EnemyArchetype
			if not archetype.is_structurally_valid() or not ResourceLoader.exists(archetype.actor_scene_path, "PackedScene"):
				result.add_error(&"invalid_enemy_archetype", path + ".definition_id", "EnemyArchetype '%s' no tiene escena válida" % enemy_id)


static func _validate_resources(value: Variant, result: LevelValidationResult) -> void:
	if not value is Array:
		result.add_error(&"invalid_type", "resources", "se esperaba array")
		return
	for index: int in (value as Array).size():
		var resource: Variant = (value as Array)[index]
		var path := "resources[%d]" % index
		if not resource is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var resource_data := resource as Dictionary
		_validate_identity(resource_data.get("id", ""), path + ".id", result)
		_validate_identity(resource_data.get("kind", ""), path + ".kind", result)
		_validate_vector(resource_data, path, result)
		var ownership := String(resource_data.get("ownership", ""))
		if ownership not in RESOURCE_OWNERSHIP:
			result.add_error(&"invalid_ownership", path + ".ownership", "semántica desconocida '%s'" % ownership)


static func _validate_mission_rewards_on_base_route(spec: LevelSpec, result: LevelValidationResult) -> void:
	if not spec.data.get("resources") is Array or not spec.data.get("platforms") is Array:
		return
	var required_platforms: Array = (spec.data.get("platforms") as Array).filter(
		func(platform: Variant) -> bool: return platform is Dictionary and bool((platform as Dictionary).get("required", true))
	)
	for index: int in (spec.data.get("resources") as Array).size():
		var resource_value: Variant = (spec.data.get("resources") as Array)[index]
		if not resource_value is Dictionary:
			continue
		var resource_data := resource_value as Dictionary
		if String(resource_data.get("ownership", "")) != "mission_reward":
			continue
		if _support_index(resource_data, required_platforms) < 0:
			result.add_error(
				&"mission_reward_off_base_route",
				"resources[%d]" % index,
				"una recompensa de misión debe poder recogerse desde una plataforma de la ruta base"
			)


static func _validate_sections(value: Variant, result: LevelValidationResult) -> void:
	if not value is Array or (value as Array).is_empty():
		result.add_error(&"missing_sections", "sections", "se requiere al menos una sección")
		return
	for index: int in (value as Array).size():
		var section: Variant = (value as Array)[index]
		if not section is Dictionary:
			result.add_error(&"invalid_type", "sections[%d]" % index, "se esperaba objeto")
		else:
			var section_data := section as Dictionary
			_validate_identity(section_data.get("id", ""), "sections[%d].id" % index, result)
			if float(section_data.get("to_x", 0.0)) <= float(section_data.get("from_x", 0.0)):
				result.add_error(&"invalid_section", "sections[%d]" % index, "to_x debe ser mayor que from_x")


static func _validate_checkpoints(value: Variant, result: LevelValidationResult) -> void:
	if not value is Array:
		result.add_error(&"invalid_type", "checkpoints", "se esperaba array")
		return
	for index: int in (value as Array).size():
		var data: Variant = (value as Array)[index]
		var path := "checkpoints[%d]" % index
		if not data is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var checkpoint := data as Dictionary
		_validate_identity(checkpoint.get("id", ""), path + ".id", result)
		_validate_vector(checkpoint, path, result)
		if not checkpoint.has("respawn_x") or not checkpoint.has("respawn_y"):
			result.add_error(&"missing_field", path, "faltan respawn_x/respawn_y")


static func _validate_gates(value: Variant, registry: ContentRegistry, rule_ids_value: Variant, result: LevelValidationResult) -> void:
	if not value is Array:
		result.add_error(&"invalid_type", "gates", "se esperaba array")
		return
	var counterplay_tags: Array[StringName] = []
	if rule_ids_value is Array and not (rule_ids_value as Array).is_empty():
		var rule := registry.get_definition(ContentRegistry.Kind.IDEOLOGY_RULE, StringName(String((rule_ids_value as Array)[0]))) as IdeologyRuleDefinition
		if rule != null:
			counterplay_tags = rule.counterplay_tags
	for index: int in (value as Array).size():
		var data: Variant = (value as Array)[index]
		var path := "gates[%d]" % index
		if not data is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var gate := data as Dictionary
		_validate_identity(gate.get("id", ""), path + ".id", result)
		_validate_vector(gate, path, result)
		var required_tag := StringName(String(gate.get("required_tag", "")))
		_validate_identity(required_tag, path + ".required_tag", result)
		if required_tag not in counterplay_tags:
			result.add_error(&"missing_counterplay", path + ".required_tag", "el tag no está declarado por la regla activa")


static func _validate_movement_and_reachability(spec: LevelSpec, result: LevelValidationResult) -> void:
	var profile_path := String(spec.data.get("movement_profile_path", ""))
	if not ResourceLoader.exists(profile_path, "Resource"):
		result.add_error(&"missing_resource", "movement_profile_path", "no existe '%s'" % profile_path)
		return
	var profile := load(profile_path) as PlayerMovementProfile
	if profile == null or not profile.is_valid():
		result.add_error(&"invalid_resource", "movement_profile_path", "no es un PlayerMovementProfile válido")
		return
	if not spec.data.get("platforms") is Array:
		return
	var platforms: Array = (spec.data.get("platforms") as Array).filter(
		func(platform: Variant) -> bool: return platform is Dictionary and bool((platform as Dictionary).get("required", true))
	)
	if platforms.is_empty():
		return
	var spawn_index := _support_index(spec.data.get("player_spawn") as Dictionary, platforms)
	var exit_index := _support_index(spec.data.get("exit") as Dictionary, platforms)
	if spawn_index < 0:
		result.add_error(&"spawn_without_support", "player_spawn", "no existe plataforma requerida bajo el spawn")
	if exit_index < 0:
		result.add_error(&"exit_without_support", "exit", "no existe plataforma requerida bajo la salida")
	if spawn_index < 0 or exit_index < 0:
		return
	if not _is_reachable(spawn_index, exit_index, platforms, profile):
		result.add_error(
			&"unreachable_required_route",
			"platforms",
			"la ruta spawn->exit excede alcance seguro %.1f px o altura %.1f px" % [
				MovementMath.conservative_horizontal_reach(profile),
				MovementMath.maximum_jump_height(profile),
			]
		)


static func _support_index(point: Dictionary, platforms: Array) -> int:
	var x := float(point.get("x", 0.0))
	var y := float(point.get("y", 0.0))
	var best_index := -1
	var best_distance := INF
	for index: int in platforms.size():
		var platform := platforms[index] as Dictionary
		var left := float(platform.get("x", 0.0))
		var right := left + float(platform.get("width", 0.0))
		var top := float(platform.get("y", 0.0))
		var vertical_distance := top - y
		if x >= left and x <= right and vertical_distance >= 0.0 and vertical_distance <= 128.0 and vertical_distance < best_distance:
			best_index = index
			best_distance = vertical_distance
	return best_index


static func _is_reachable(start: int, destination: int, platforms: Array, profile: PlayerMovementProfile) -> bool:
	var pending: Array[int] = [start]
	var visited: Dictionary = {start: true}
	while not pending.is_empty():
		var current: int = pending.pop_front()
		if current == destination:
			return true
		for candidate: int in platforms.size():
			if visited.has(candidate) or not _can_jump(platforms[current], platforms[candidate], profile):
				continue
			visited[candidate] = true
			pending.append(candidate)
	return false


static func _can_jump(from_value: Variant, to_value: Variant, profile: PlayerMovementProfile) -> bool:
	var from := from_value as Dictionary
	var to := to_value as Dictionary
	var from_left := float(from.get("x", 0.0))
	var from_right := from_left + float(from.get("width", 0.0))
	var to_left := float(to.get("x", 0.0))
	var to_right := to_left + float(to.get("width", 0.0))
	var horizontal_gap := maxf(maxf(to_left - from_right, from_left - to_right), 0.0)
	var upward_rise := maxf(float(from.get("y", 0.0)) - float(to.get("y", 0.0)), 0.0)
	return (
		horizontal_gap <= MovementMath.conservative_horizontal_reach(profile)
		and upward_rise <= MovementMath.maximum_jump_height(profile) * 0.9
	)
