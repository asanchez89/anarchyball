class_name ContentBatchValidator
extends RefCounted


static func validate(
	catalog: ContentCatalog,
	catalog_path: String,
	level_paths: PackedStringArray
) -> PackedStringArray:
	var errors := PackedStringArray()
	var registry := ContentRegistry.new()
	if not registry.register_catalog(catalog, catalog_path):
		errors.append_array(registry.errors())
	if catalog == null:
		return errors
	_validate_catalog(catalog, catalog_path, registry, errors)
	for level_path: String in level_paths:
		_validate_level(level_path, registry, errors)
	return errors


static func _validate_catalog(
	catalog: ContentCatalog,
	source_path: String,
	registry: ContentRegistry,
	errors: PackedStringArray
) -> void:
	for index: int in catalog.class_loadouts.size():
		var definition := catalog.class_loadouts[index]
		if definition == null or not definition.is_structurally_valid():
			_add_error(errors, source_path, "class_loadouts[%d]" % index, &"invalid_class_loadout", "requiere ID, weapon_id y multiplicador de movimiento positivo")
	for index: int in catalog.enemy_archetypes.size():
		var definition := catalog.enemy_archetypes[index]
		var field := "enemy_archetypes[%d]" % index
		if definition == null or not definition.is_structurally_valid():
			_add_error(errors, source_path, field, &"invalid_enemy_archetype", "requiere ID, escena, behavior, razón para behavior activo y valores positivos")
			continue
		if not ResourceLoader.exists(definition.actor_scene_path, "PackedScene"):
			_add_error(errors, source_path, field + ".actor_scene_path", &"missing_resource", "no existe '%s'" % definition.actor_scene_path)
	for index: int in catalog.ideology_rules.size():
		var definition := catalog.ideology_rules[index]
		var field := "ideology_rules[%d]" % index
		if definition == null:
			_add_error(errors, source_path, field, &"invalid_ideology_rule", "definición nula")
			continue
		if not IdeologyRuleDefinition.is_supported_hook(definition.hook_id):
			_add_error(errors, source_path, field + ".hook_id", &"unsupported_rule_hook", "hook no soportado '%s'" % definition.hook_id)
		elif not definition.is_structurally_valid():
			_add_error(errors, source_path, field, &"invalid_ideology_rule", "requiere ID, hook soportado y counterplay")
	for index: int in catalog.encounter_definitions.size():
		var definition := catalog.encounter_definitions[index]
		var field := "encounter_definitions[%d]" % index
		if definition == null or not definition.is_structurally_valid():
			_add_error(errors, source_path, field, &"invalid_encounter", "requiere ID, objetivo, éxito, resolución y trigger si es boss")
			continue
		if not definition.protected_archetype_id.is_empty() and not registry.has(ContentRegistry.Kind.ENEMY_ARCHETYPE, definition.protected_archetype_id):
			_add_error(errors, source_path, field + ".protected_archetype_id", &"unknown_reference", "ID no registrado '%s'" % definition.protected_archetype_id)
		for enemy_index: int in definition.enemy_archetype_ids.size():
			var enemy_id := definition.enemy_archetype_ids[enemy_index]
			if not registry.has(ContentRegistry.Kind.ENEMY_ARCHETYPE, enemy_id):
				_add_error(errors, source_path, field + ".enemy_archetype_ids[%d]" % enemy_index, &"unknown_reference", "ID no registrado '%s'" % enemy_id)


static func _validate_level(path: String, registry: ContentRegistry, errors: PackedStringArray) -> void:
	var load_result := LevelSpecLoader.load_file(path)
	if not load_result.is_success():
		errors.append_array(load_result.errors)
		return
	var validation := LevelValidator.validate(load_result.spec, registry)
	errors.append_array(validation.formatted_errors())


static func _add_error(
	errors: PackedStringArray,
	source_path: String,
	field_path: String,
	code: StringName,
	message: String
) -> void:
	errors.append("%s: %s [%s]: %s" % [source_path, field_path, code, message])
