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
const ROOT_FIELDS: PackedStringArray = [
	"schema_version", "level_id", "display_name", "player_spawn", "exit", "bounds",
	"movement_profile_path", "class_loadout_id", "ideology_rule_ids", "platforms",
	"encounters", "resources", "sections", "checkpoints", "gates", "rule_objects", "slice",
	"contracts", "actors",
]
const POINT_FIELDS: PackedStringArray = ["x", "y"]
const BOUNDS_FIELDS: PackedStringArray = ["width", "height"]
const PLATFORM_FIELDS: PackedStringArray = ["id", "x", "y", "width", "height", "required", "route_tags", "art_style", "motion_distance_y", "motion_speed"]
const PLATFORM_ART_STYLES: PackedStringArray = ["road", "column_supported"]
const ENCOUNTER_FIELDS: PackedStringArray = ["id", "definition_id", "x", "y", "enemy_count", "enemy_positions", "rule_object_ids", "resource_ids", "resolution_gate_id", "required_for_completion", "resolution_platform_ids"]
const RESOURCE_FIELDS: PackedStringArray = ["id", "kind", "x", "y", "ownership", "effect_id", "effect_amount"]
const SECTION_FIELDS: PackedStringArray = ["id", "from_x", "to_x"]
const CHECKPOINT_FIELDS: PackedStringArray = ["id", "x", "y", "respawn_x", "respawn_y"]
const GATE_FIELDS: PackedStringArray = ["id", "x", "y", "width", "height", "required_tag", "key_resource_id", "label"]
const RULE_OBJECT_FIELDS: PackedStringArray = ["id", "hook_id", "x", "y", "initial_state", "target_platform_ids", "interaction_tag", "targets_enabled_before_interaction", "requires", "label", "hint", "visual_kind", "call_only", "service_gate_id"]
const CONTRACT_FIELDS: PackedStringArray = ["id", "definition_id", "x", "y", "acceptance_gate_id", "resolution_gate_id", "encounter_id", "performance_x", "resolution_x", "resolution_y", "counterparty_escape_x"]
const ACTOR_FIELDS: PackedStringArray = ["id", "archetype_id", "x", "y"]
const SLICE_FIELDS: PackedStringArray = ["title", "objective", "intro", "completion", "briefing_cards"]
const BRIEFING_CARD_FIELDS: PackedStringArray = ["title", "body", "image_path", "image_columns", "image_rows", "image_frame"]
const LOCAL_ID_COLLECTIONS: PackedStringArray = ["platforms", "encounters", "resources", "sections", "checkpoints", "gates", "rule_objects", "contracts", "actors"]
const RULE_OBJECT_STATES: PackedStringArray = ["inactive", "available", "occupied", "disabled", "abandoned", "disputed"]
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
	_validate_closed_shapes(spec, result)
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
	_validate_encounters(spec, registry, result)
	_validate_resources(spec.data.get("resources"), result)
	_validate_mission_rewards_on_base_route(spec, result)
	_validate_sections(spec.data.get("sections"), result)
	_validate_checkpoints(spec.data.get("checkpoints", []), result)
	_validate_gates(spec, registry, result)
	_validate_rule_objects(spec, registry, result)
	_validate_mechanism_links(spec, result)
	_validate_contracts(spec, registry, result)
	_validate_actors(spec, registry, result)
	_validate_unique_local_ids(spec, result)
	_validate_placement_bounds(spec, result)
	_validate_movement_and_reachability(spec, result)
	return result


static func _validate_identity(value: Variant, path: String, result: LevelValidationResult) -> void:
	var content_id := StringName(String(value))
	if not ContentId.is_valid(content_id):
		result.add_error(&"invalid_id", path, "'%s' debe ser snake_case estable" % value)


static func _validate_mechanism_links(spec: LevelSpec, result: LevelValidationResult) -> void:
	var machines: Dictionary = {}
	var platforms: Dictionary = {}
	for value: Variant in spec.data.get("platforms", []) as Array:
		if value is Dictionary:
			platforms[String(value.get("id", ""))] = value
	for value: Variant in spec.data.get("rule_objects", []) as Array:
		if value is Dictionary:
			machines[String(value.get("id", ""))] = value
	for id: String in machines:
		var data := machines[id] as Dictionary
		var path := "rule_objects.%s" % id
		if not data.get("requires", []) is Array:
			result.add_error(&"invalid_type", path + ".requires", "se esperaba array")
			continue
		for field: String in ["label", "hint", "visual_kind"]:
			if data.has(field) and not data[field] is String:
				result.add_error(&"invalid_type", path + "." + field, "se esperaba texto")
		if data.get("visual_kind", "machine") not in ["machine", "signal"]:
			result.add_error(&"invalid_value", path + ".visual_kind", "visual desconocido")
		if not data.get("call_only", false) is bool:
			result.add_error(&"invalid_type", path + ".call_only", "se esperaba booleano")
		for dependency: Variant in data.get("requires", []) as Array:
			if not machines.has(String(dependency)):
				result.add_error(&"unknown_local_reference", path + ".requires", "control no declarado")
		if _dependency_cycle(id, machines, []):
			result.add_error(&"cyclic_mechanism", path + ".requires", "dependencia circular")
		if bool(data.get("call_only", false)):
			for target: Variant in data.get("target_platform_ids", []) as Array:
				if platforms.has(String(target)) and is_zero_approx(float(platforms[String(target)].get("motion_distance_y", 0.0))):
					result.add_error(&"invalid_call_target", path, "llamada requiere ascensor móvil")
	for value: Variant in spec.data.get("encounters", []) as Array:
		if not value is Dictionary:
			continue
		var data := value as Dictionary
		if not data.get("resolution_platform_ids", []) is Array:
			result.add_error(&"invalid_type", "encounters.resolution_platform_ids", "se esperaba array")
			continue
		for target: Variant in data.get("resolution_platform_ids", []) as Array:
			if not platforms.has(String(target)):
				result.add_error(&"unknown_local_reference", "encounters.resolution_platform_ids", "plataforma no declarada")


static func _dependency_cycle(id: String, machines: Dictionary, visiting: Array[String]) -> bool:
	if id in visiting:
		return true
	if not machines.has(id):
		return false
	var path: Array[String] = visiting.duplicate()
	path.append(id)
	var dependencies: Variant = (machines[id] as Dictionary).get("requires", [])
	if dependencies is Array:
		for dependency: Variant in dependencies:
			if _dependency_cycle(String(dependency), machines, path):
				return true
	return false


static func _validate_closed_shapes(spec: LevelSpec, result: LevelValidationResult) -> void:
	_validate_known_fields(spec.data, "root", ROOT_FIELDS, result)
	_validate_dictionary_shape(spec.data.get("player_spawn"), "player_spawn", POINT_FIELDS, result)
	_validate_dictionary_shape(spec.data.get("exit"), "exit", POINT_FIELDS, result)
	_validate_dictionary_shape(spec.data.get("bounds"), "bounds", BOUNDS_FIELDS, result)
	_validate_dictionary_shape(spec.data.get("slice", {}), "slice", SLICE_FIELDS, result)
	var slice_data := spec.data.get("slice", {}) as Dictionary
	_validate_array_shapes(slice_data.get("briefing_cards", []), "slice.briefing_cards", BRIEFING_CARD_FIELDS, result)
	_validate_array_shapes(spec.data.get("platforms"), "platforms", PLATFORM_FIELDS, result)
	_validate_array_shapes(spec.data.get("encounters"), "encounters", ENCOUNTER_FIELDS, result)
	_validate_array_shapes(spec.data.get("resources"), "resources", RESOURCE_FIELDS, result)
	_validate_array_shapes(spec.data.get("sections"), "sections", SECTION_FIELDS, result)
	_validate_array_shapes(spec.data.get("checkpoints", []), "checkpoints", CHECKPOINT_FIELDS, result)
	_validate_array_shapes(spec.data.get("gates", []), "gates", GATE_FIELDS, result)
	_validate_array_shapes(spec.data.get("rule_objects", []), "rule_objects", RULE_OBJECT_FIELDS, result)
	_validate_array_shapes(spec.data.get("contracts", []), "contracts", CONTRACT_FIELDS, result)
	_validate_array_shapes(spec.data.get("actors", []), "actors", ACTOR_FIELDS, result)


static func _validate_actors(spec: LevelSpec, registry: ContentRegistry, result: LevelValidationResult) -> void:
	var value: Variant = spec.data.get("actors", [])
	if not value is Array:
		result.add_error(&"invalid_type", "actors", "se esperaba array")
		return
	for index: int in (value as Array).size():
		var path := "actors[%d]" % index
		var actor_value: Variant = (value as Array)[index]
		if not actor_value is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var actor := actor_value as Dictionary
		_validate_identity(actor.get("id", ""), path + ".id", result)
		_validate_vector(actor, path, result)
		var archetype_id := StringName(String(actor.get("archetype_id", "")))
		_validate_reference(registry, ContentRegistry.Kind.ENEMY_ARCHETYPE, archetype_id, path + ".archetype_id", result)
		var archetype := registry.get_definition(ContentRegistry.Kind.ENEMY_ARCHETYPE, archetype_id) as EnemyArchetype
		if archetype != null and (not archetype.is_structurally_valid() or not ResourceLoader.exists(archetype.actor_scene_path, "PackedScene")):
			result.add_error(&"invalid_enemy_archetype", path + ".archetype_id", "EnemyArchetype '%s' no tiene escena válida" % archetype_id)


static func _validate_array_shapes(value: Variant, path: String, allowed_fields: PackedStringArray, result: LevelValidationResult) -> void:
	if not value is Array:
		return
	for index: int in (value as Array).size():
		_validate_dictionary_shape((value as Array)[index], "%s[%d]" % [path, index], allowed_fields, result)


static func _validate_dictionary_shape(value: Variant, path: String, allowed_fields: PackedStringArray, result: LevelValidationResult) -> void:
	if value is Dictionary:
		_validate_known_fields(value as Dictionary, path, allowed_fields, result)


static func _validate_known_fields(data: Dictionary, path: String, allowed_fields: PackedStringArray, result: LevelValidationResult) -> void:
	for key_value: Variant in data.keys():
		var key := String(key_value)
		if key not in allowed_fields:
			result.add_error(&"unknown_field", key if path == "root" else path + "." + key, "campo no permitido por LevelSpec v0")


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
		var art_style := String(data.get("art_style", "road" if bool(data.get("required", true)) else "column_supported"))
		if art_style not in PLATFORM_ART_STYLES:
			result.add_error(&"invalid_platform_art_style", path + ".art_style", "se esperaba road o column_supported")
		var motion_distance := float(data.get("motion_distance_y", 0.0))
		var motion_speed := float(data.get("motion_speed", 0.0))
		if (not is_zero_approx(motion_distance) and motion_speed <= 0.0) or (is_zero_approx(motion_distance) and motion_speed > 0.0):
			result.add_error(&"invalid_platform_motion", path, "motion_distance_y y motion_speed deben declararse juntos")
		if not data.get("route_tags", []) is Array:
			result.add_error(&"invalid_type", path + ".route_tags", "se esperaba array")
			continue
		var route_tags := data.get("route_tags", []) as Array
		if not bool(data.get("required", true)) and route_tags.is_empty():
			result.add_error(&"missing_route_tag", path + ".route_tags", "una ruta opcional debe declarar tags")
		for tag_index: int in route_tags.size():
			_validate_identity(route_tags[tag_index], path + ".route_tags[%d]" % tag_index, result)


static func _validate_encounters(spec: LevelSpec, registry: ContentRegistry, result: LevelValidationResult) -> void:
	var value: Variant = spec.data.get("encounters")
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
		if encounter_data.has("required_for_completion") and not encounter_data.get("required_for_completion") is bool:
			result.add_error(&"invalid_type", path + ".required_for_completion", "se esperaba bool")
		if encounter_data.has("enemy_count"):
			var count_value: Variant = encounter_data.get("enemy_count")
			if (not count_value is float and not count_value is int) or not is_equal_approx(float(count_value), roundf(float(count_value))):
				result.add_error(&"invalid_type", path + ".enemy_count", "se esperaba entero")
			elif int(count_value) < 1:
				result.add_error(&"invalid_value", path + ".enemy_count", "se requiere al menos una ball")
		var rule_object_ids: Variant = encounter_data.get("rule_object_ids", [])
		if not rule_object_ids is Array:
			result.add_error(&"invalid_type", path + ".rule_object_ids", "se esperaba array")
		else:
			var available_rule_object_ids: Array[StringName] = []
			for rule_object_value: Variant in spec.data.get("rule_objects", []) as Array:
				if rule_object_value is Dictionary:
					available_rule_object_ids.append(StringName(String((rule_object_value as Dictionary).get("id"))))
			for rule_index: int in (rule_object_ids as Array).size():
				var object_id := StringName(String((rule_object_ids as Array)[rule_index]))
				_validate_identity(object_id, "%s.rule_object_ids[%d]" % [path, rule_index], result)
				if object_id not in available_rule_object_ids:
					result.add_error(&"unknown_local_reference", "%s.rule_object_ids[%d]" % [path, rule_index], "rule object no declarado '%s'" % object_id)
		var resource_ids: Variant = encounter_data.get("resource_ids", [])
		if not resource_ids is Array:
			result.add_error(&"invalid_type", path + ".resource_ids", "se esperaba array")
		else:
			var available_resource_ids: Array[StringName] = []
			for resource_value: Variant in spec.data.get("resources", []) as Array:
				if resource_value is Dictionary:
					available_resource_ids.append(StringName(String((resource_value as Dictionary).get("id"))))
			for resource_index: int in (resource_ids as Array).size():
				var resource_id := StringName(String((resource_ids as Array)[resource_index]))
				_validate_identity(resource_id, "%s.resource_ids[%d]" % [path, resource_index], result)
				if resource_id not in available_resource_ids:
					result.add_error(&"unknown_local_reference", "%s.resource_ids[%d]" % [path, resource_index], "recurso no declarado '%s'" % resource_id)
		if encounter_data.has("resolution_gate_id"):
			var resolution_gate_id := StringName(String(encounter_data.get("resolution_gate_id")))
			_validate_identity(resolution_gate_id, path + ".resolution_gate_id", result)
			var available_gate_ids: Array[StringName] = []
			for gate_value: Variant in spec.data.get("gates", []) as Array:
				if gate_value is Dictionary:
					available_gate_ids.append(StringName(String((gate_value as Dictionary).get("id"))))
			if resolution_gate_id not in available_gate_ids:
				result.add_error(&"unknown_local_reference", path + ".resolution_gate_id", "gate no declarado '%s'" % resolution_gate_id)
		var definition_id: Variant = encounter_data.get("definition_id", "")
		_validate_reference(registry, ContentRegistry.Kind.ENCOUNTER_DEFINITION, definition_id, path + ".definition_id", result)
		var definition := registry.get_definition(ContentRegistry.Kind.ENCOUNTER_DEFINITION, StringName(String(definition_id))) as EncounterDefinition
		if definition == null:
			continue
		if definition.ceasefire_challenge != null and definition.ceasefire_challenge.mode == CeasefireChallengeDefinition.AttackMode.MIXED_STAGES:
			var group_total := 0
			for count: int in definition.ceasefire_challenge.group_sizes:
				group_total += count
			if group_total != int(encounter_data.get("enemy_count", definition.enemy_archetype_ids.size())):
				result.add_error(&"invalid_group_roster", path, "la composición no coincide con los grupos de tregua")
		if encounter_data.has("enemy_positions"):
			var points: Variant = encounter_data.enemy_positions
			_validate_array_shapes(points, path + ".enemy_positions", POINT_FIELDS, result)
			if points is Array:
				if points.size() != int(encounter_data.get("enemy_count", definition.enemy_archetype_ids.size())):
					result.add_error(&"invalid_enemy_positions", path + ".enemy_positions", "se requiere un punto por integrante")
				for point_index: int in points.size():
					if points[point_index] is Dictionary:
						_validate_vector(points[point_index], path + ".enemy_positions[%d]" % point_index, result)
						_validate_point_in_bounds(points[point_index], spec.data.bounds, path + ".enemy_positions[%d]" % point_index, result)
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
		if resource_data.has("effect_id") and StringName(String(resource_data.get("effect_id"))) != &"health_restore":
			result.add_error(&"invalid_pickup_effect", path + ".effect_id", "efecto de pickup desconocido")
		if resource_data.has("effect_amount") and (not resource_data.get("effect_amount") is float and not resource_data.get("effect_amount") is int):
			result.add_error(&"invalid_type", path + ".effect_amount", "se esperaba número")


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


static func _validate_gates(spec: LevelSpec, registry: ContentRegistry, result: LevelValidationResult) -> void:
	var value: Variant = spec.data.get("gates", [])
	if not value is Array:
		result.add_error(&"invalid_type", "gates", "se esperaba array")
		return
	var counterplay_tags: Array[StringName] = []
	var encounter_gate_ids: Dictionary = {}
	var encounters_value: Variant = spec.data.get("encounters", [])
	if encounters_value is Array:
		for encounter_value: Variant in encounters_value as Array:
			if encounter_value is Dictionary:
				var encounter_gate_id := StringName(String((encounter_value as Dictionary).get("resolution_gate_id", "")))
				if not encounter_gate_id.is_empty():
					encounter_gate_ids[encounter_gate_id] = true
	var rule_ids_value: Variant = spec.data.get("ideology_rule_ids")
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
		if required_tag == &"mission_key":
			var key_id := String(gate.get("key_resource_id", ""))
			var found := false
			for resource: Dictionary in spec.data.get("resources", []):
				if String(resource.id) == key_id and String(resource.get("kind", "")) == "key":
					found = true
			if not found:
				result.add_error(&"missing_key", path, "llave ausente del nivel")
			continue
		if required_tag == &"encounter_resolution":
			var gate_id := StringName(String(gate.get("id", "")))
			if not encounter_gate_ids.has(gate_id):
				result.add_error(&"orphan_encounter_gate", path + ".id", "ningún encuentro resuelve esta barrera")
			continue
		if required_tag == &"mechanical_service":
			var linked := false
			for machine: Dictionary in spec.data.get("rule_objects", []):
				if String(machine.get("service_gate_id", "")) == String(gate.id):
					linked = true
			if not linked:
				result.add_error(&"orphan_service_gate", path, "compuerta sin terminal")
			continue
		if required_tag not in counterplay_tags:
			result.add_error(&"missing_counterplay", path + ".required_tag", "el tag no está declarado por la regla activa")


static func _validate_rule_objects(spec: LevelSpec, registry: ContentRegistry, result: LevelValidationResult) -> void:
	var value: Variant = spec.data.get("rule_objects", [])
	if not value is Array:
		result.add_error(&"invalid_type", "rule_objects", "se esperaba array")
		return
	var active_rule: IdeologyRuleDefinition
	var rule_ids: Variant = spec.data.get("ideology_rule_ids")
	if rule_ids is Array and not (rule_ids as Array).is_empty() and registry != null:
		active_rule = registry.get_definition(
			ContentRegistry.Kind.IDEOLOGY_RULE,
			StringName(String((rule_ids as Array)[0]))
		) as IdeologyRuleDefinition
	var platform_ids: Dictionary = {}
	var platforms: Variant = spec.data.get("platforms")
	if platforms is Array:
		for platform_value: Variant in platforms as Array:
			if platform_value is Dictionary:
				var platform_id := StringName(String((platform_value as Dictionary).get("id", "")))
				if not platform_id.is_empty():
					platform_ids[platform_id] = true
	for index: int in (value as Array).size():
		var object_value: Variant = (value as Array)[index]
		var path := "rule_objects[%d]" % index
		if not object_value is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var data := object_value as Dictionary
		_validate_identity(data.get("id", ""), path + ".id", result)
		_validate_vector(data, path, result)
		var hook_id := StringName(String(data.get("hook_id", "")))
		_validate_identity(hook_id, path + ".hook_id", result)
		if not IdeologyRuleDefinition.is_supported_hook(hook_id):
			result.add_error(&"unsupported_rule_hook", path + ".hook_id", "hook no soportado '%s'" % hook_id)
		elif active_rule == null or hook_id != active_rule.hook_id:
			result.add_error(&"rule_hook_mismatch", path + ".hook_id", "el hook debe coincidir con la regla ideológica activa")
		var initial_state := String(data.get("initial_state", ""))
		if initial_state not in RULE_OBJECT_STATES:
			result.add_error(&"invalid_rule_state", path + ".initial_state", "estado no soportado '%s'" % initial_state)
		var target_ids: Variant = data.get("target_platform_ids")
		var service_gate := String(data.get("service_gate_id", ""))
		if not service_gate.is_empty():
			var found := false
			for gate: Dictionary in spec.data.get("gates", []):
				if String(gate.id) == service_gate and String(gate.required_tag) == "mechanical_service":
					found = true
			if not found:
				result.add_error(&"unknown_service_gate", path, "compuerta mecánica no declarada")
		if not target_ids is Array or ((target_ids as Array).is_empty() and service_gate.is_empty()):
			result.add_error(&"missing_targets", path + ".target_platform_ids", "se requiere al menos una plataforma objetivo")
		else:
			for target_index: int in (target_ids as Array).size():
				var target_id := StringName(String((target_ids as Array)[target_index]))
				_validate_identity(target_id, path + ".target_platform_ids[%d]" % target_index, result)
				if not platform_ids.has(target_id):
					result.add_error(&"unknown_local_reference", path + ".target_platform_ids[%d]" % target_index, "plataforma no declarada '%s'" % target_id)
		var interaction_tag := StringName(String(data.get("interaction_tag", "")))
		_validate_identity(interaction_tag, path + ".interaction_tag", result)
		if active_rule != null and interaction_tag not in active_rule.counterplay_tags:
			result.add_error(&"missing_counterplay", path + ".interaction_tag", "el tag no está declarado por la regla activa")


static func _validate_contracts(spec: LevelSpec, registry: ContentRegistry, result: LevelValidationResult) -> void:
	var value: Variant = spec.data.get("contracts", [])
	if not value is Array:
		result.add_error(&"invalid_type", "contracts", "se esperaba array")
		return
	var gate_ids: Array[StringName] = []
	for gate_value: Variant in spec.data.get("gates", []) as Array:
		if gate_value is Dictionary:
			gate_ids.append(StringName(String((gate_value as Dictionary).get("id", ""))))
	var encounter_ids: Array[StringName] = []
	for encounter_value: Variant in spec.data.get("encounters", []) as Array:
		if encounter_value is Dictionary:
			encounter_ids.append(StringName(String((encounter_value as Dictionary).get("id", ""))))
	var bounds := spec.data.get("bounds", {}) as Dictionary
	for index: int in (value as Array).size():
		var path := "contracts[%d]" % index
		var placement_value: Variant = (value as Array)[index]
		if not placement_value is Dictionary:
			result.add_error(&"invalid_type", path, "se esperaba objeto")
			continue
		var placement := placement_value as Dictionary
		_validate_identity(placement.get("id", ""), path + ".id", result)
		_validate_vector(placement, path, result)
		_validate_reference(registry, ContentRegistry.Kind.CONTRACT_DEFINITION, placement.get("definition_id", ""), path + ".definition_id", result)
		for field: String in ["acceptance_gate_id", "resolution_gate_id"]:
			var gate_id := StringName(String(placement.get(field, "")))
			_validate_identity(gate_id, path + "." + field, result)
			if gate_id not in gate_ids:
				result.add_error(&"unknown_local_reference", path + "." + field, "gate no declarado '%s'" % gate_id)
		var encounter_id := StringName(String(placement.get("encounter_id", "")))
		_validate_identity(encounter_id, path + ".encounter_id", result)
		if encounter_id not in encounter_ids:
			result.add_error(&"unknown_local_reference", path + ".encounter_id", "encounter no declarado '%s'" % encounter_id)
		for field: String in ["performance_x", "resolution_x", "resolution_y", "counterparty_escape_x"]:
			if not placement.has(field) or (not placement.get(field) is float and not placement.get(field) is int):
				result.add_error(&"invalid_type", path + "." + field, "se esperaba número")
		if float(placement.get("performance_x", -1.0)) < 0.0 or float(placement.get("performance_x", -1.0)) > float(bounds.get("width", 0.0)):
			result.add_error(&"point_out_of_bounds", path + ".performance_x", "debe quedar dentro de bounds")
		_validate_point_in_bounds({"x": placement.get("resolution_x", -1.0), "y": placement.get("resolution_y", -1.0)}, bounds, path + ".resolution", result)
		if float(placement.get("counterparty_escape_x", -1.0)) < 0.0 or float(placement.get("counterparty_escape_x", -1.0)) > float(bounds.get("width", 0.0)):
			result.add_error(&"point_out_of_bounds", path + ".counterparty_escape_x", "debe quedar dentro de bounds")


static func _validate_unique_local_ids(spec: LevelSpec, result: LevelValidationResult) -> void:
	var locations: Dictionary = {}
	for collection: String in LOCAL_ID_COLLECTIONS:
		var value: Variant = spec.data.get(collection, [])
		if not value is Array:
			continue
		for index: int in (value as Array).size():
			var item: Variant = (value as Array)[index]
			if not item is Dictionary:
				continue
			var content_id := StringName(String((item as Dictionary).get("id", "")))
			if content_id.is_empty():
				continue
			var path := "%s[%d].id" % [collection, index]
			if locations.has(content_id):
				result.add_error(&"duplicate_local_id", path, "ID '%s' ya declarado en %s" % [content_id, locations[content_id]])
			else:
				locations[content_id] = path


static func _validate_placement_bounds(spec: LevelSpec, result: LevelValidationResult) -> void:
	var bounds: Variant = spec.data.get("bounds")
	if not bounds is Dictionary:
		return
	for collection: String in ["encounters", "resources", "checkpoints", "gates", "rule_objects", "contracts", "actors"]:
		var value: Variant = spec.data.get(collection, [])
		if not value is Array:
			continue
		for index: int in (value as Array).size():
			_validate_point_in_bounds((value as Array)[index], bounds, "%s[%d]" % [collection, index], result)
	var platforms: Variant = spec.data.get("platforms")
	if platforms is Array:
		for index: int in (platforms as Array).size():
			var platform_value: Variant = (platforms as Array)[index]
			if not platform_value is Dictionary:
				continue
			var platform := platform_value as Dictionary
			var x := float(platform.get("x", -1.0))
			var y := float(platform.get("y", -1.0))
			var width := float(platform.get("width", 0.0))
			var height := float(platform.get("height", 0.0))
			if x < 0.0 or y < 0.0 or x + width > float((bounds as Dictionary).get("width", 0.0)) or y + height > float((bounds as Dictionary).get("height", 0.0)):
				result.add_error(&"geometry_out_of_bounds", "platforms[%d]" % index, "la geometría debe quedar dentro de bounds")
	var sections: Variant = spec.data.get("sections")
	if sections is Array:
		for index: int in (sections as Array).size():
			var section_value: Variant = (sections as Array)[index]
			if not section_value is Dictionary:
				continue
			var section := section_value as Dictionary
			if float(section.get("from_x", -1.0)) < 0.0 or float(section.get("to_x", 0.0)) > float((bounds as Dictionary).get("width", 0.0)):
				result.add_error(&"section_out_of_bounds", "sections[%d]" % index, "from_x/to_x deben quedar dentro de bounds")


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
