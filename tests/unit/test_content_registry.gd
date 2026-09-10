extends GdUnitTestSuite

const CATALOG_PATH := "res://data/content/default_catalog.tres"


func test_default_catalog_registers_stable_content_ids() -> void:
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var registry := ContentRegistry.new()

	assert_bool(registry.register_catalog(catalog, CATALOG_PATH)).is_true()
	assert_bool(registry.has(ContentRegistry.Kind.CLASS_LOADOUT, &"class_contractor")).is_true()
	assert_bool(registry.has(ContentRegistry.Kind.ENEMY_ARCHETYPE, &"enemy_guard_aggressor")).is_true()
	assert_bool(registry.has(ContentRegistry.Kind.ENCOUNTER_DEFINITION, &"encounter_third_party_defense")).is_true()
	assert_bool(registry.has(ContentRegistry.Kind.IDEOLOGY_RULE, &"rule_access_contract")).is_true()


func test_content_ids_reject_display_names_and_paths() -> void:
	assert_bool(ContentId.is_valid(&"class_contractor")).is_true()
	assert_bool(ContentId.is_valid(&"Contractor")).is_false()
	assert_bool(ContentId.is_valid(&"class/contractor")).is_false()
	assert_bool(ContentId.is_valid(&"")).is_false()


func test_encounter_declares_objective_success_and_two_resolutions() -> void:
	var catalog := load(CATALOG_PATH) as ContentCatalog
	var registry := ContentRegistry.new()
	registry.register_catalog(catalog, CATALOG_PATH)
	var encounter := registry.get_definition(
		ContentRegistry.Kind.ENCOUNTER_DEFINITION,
		&"encounter_third_party_defense"
	) as EncounterDefinition

	assert_bool(encounter.is_structurally_valid()).is_true()
	assert_int(encounter.allowed_resolutions.size()).is_greater_equal(2)
