class_name ContentRegistry
extends RefCounted

enum Kind {
	CLASS_LOADOUT,
	ENEMY_ARCHETYPE,
	ENCOUNTER_DEFINITION,
	IDEOLOGY_RULE,
	CONTRACT_DEFINITION,
}

var _definitions: Dictionary = {}
var _errors: PackedStringArray = []


func register_catalog(catalog: ContentCatalog, source_path: String = "<catalog>") -> bool:
	_definitions.clear()
	_errors.clear()
	if catalog == null:
		_errors.append("%s: catalog: no se pudo cargar" % source_path)
		return false
	for definition: ClassLoadout in catalog.class_loadouts:
		_register(Kind.CLASS_LOADOUT, definition, source_path, "class_loadouts")
	for definition: EnemyArchetype in catalog.enemy_archetypes:
		_register(Kind.ENEMY_ARCHETYPE, definition, source_path, "enemy_archetypes")
	for definition: EncounterDefinition in catalog.encounter_definitions:
		_register(Kind.ENCOUNTER_DEFINITION, definition, source_path, "encounter_definitions")
	for definition: IdeologyRuleDefinition in catalog.ideology_rules:
		_register(Kind.IDEOLOGY_RULE, definition, source_path, "ideology_rules")
	for definition: ContractDefinition in catalog.contract_definitions:
		_register(Kind.CONTRACT_DEFINITION, definition, source_path, "contract_definitions")
	return _errors.is_empty()


func has(kind: Kind, content_id: StringName) -> bool:
	return _definitions.has(_key(kind, content_id))


func get_definition(kind: Kind, content_id: StringName) -> ContentDefinition:
	return _definitions.get(_key(kind, content_id)) as ContentDefinition


func errors() -> PackedStringArray:
	return _errors.duplicate()


func _register(
	kind: Kind,
	definition: ContentDefinition,
	source_path: String,
	field: String
) -> void:
	if definition == null:
		_errors.append("%s: %s: definición nula" % [source_path, field])
		return
	if not definition.has_valid_identity():
		_errors.append("%s: %s.content_id: ID inválido '%s'" % [source_path, field, definition.content_id])
		return
	var key := _key(kind, definition.content_id)
	if _definitions.has(key):
		_errors.append("%s: %s.content_id: ID duplicado '%s'" % [source_path, field, definition.content_id])
		return
	_definitions[key] = definition


func _key(kind: Kind, content_id: StringName) -> String:
	return "%d:%s" % [kind, content_id]
