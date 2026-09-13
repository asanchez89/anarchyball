extends GdUnitTestSuite

const CATALOG_PATH := "res://data/content/default_catalog.tres"
const WORKSHOP_PATH := "res://data/levels/occupancy_workshop_draft.json"


func test_extended_workshop_is_valid_data_driven_content() -> void:
	var load_result := LevelSpecLoader.load_file(WORKSHOP_PATH)
	var validation := LevelValidator.validate(load_result.spec, _registry())

	assert_bool(load_result.is_success()).is_true()
	assert_bool(validation.is_valid()).is_true()
	assert_str(load_result.spec.level_id()).is_equal("occupancy_workshop_draft")
	assert_object(load("res://levels/prototypes/occupancy_workshop_draft.tscn") as PackedScene).is_not_null()


func test_workshop_covers_teach_demonstrate_defend_challenge_and_combine() -> void:
	var data := LevelSpecLoader.load_file(WORKSHOP_PATH).spec.data
	var sections := data.get("sections") as Array
	var machines := data.get("rule_objects") as Array
	var encounters := data.get("encounters") as Array
	var checkpoints := data.get("checkpoints") as Array
	var resources := data.get("resources") as Array

	assert_int(sections.size()).is_equal(5)
	assert_int(machines.size()).is_equal(5)
	assert_int(encounters.size()).is_equal(2)
	assert_int(checkpoints.size()).is_equal(2)
	assert_int(resources.size()).is_equal(4)
	assert_str((sections[0] as Dictionary).get("id")).is_equal("section_teach_current_use")
	assert_str((sections[-1] as Dictionary).get("id")).is_equal("section_combine_and_exit")


func test_workshop_keeps_ground_route_required_and_machine_routes_optional() -> void:
	var data := LevelSpecLoader.load_file(WORKSHOP_PATH).spec.data
	var platforms := data.get("platforms") as Array
	var required_platforms := platforms.filter(
		func(platform: Variant) -> bool: return bool((platform as Dictionary).get("required", true))
	)
	var optional_platforms := platforms.filter(
		func(platform: Variant) -> bool: return not bool((platform as Dictionary).get("required", true))
	)

	assert_int(required_platforms.size()).is_equal(6)
	assert_int(optional_platforms.size()).is_equal(5)
	for platform_value: Variant in optional_platforms:
		assert_array((platform_value as Dictionary).get("route_tags") as Array).contains(["occupy_machine"])


func test_disputed_encounter_observes_only_its_local_machine() -> void:
	var encounters := LevelSpecLoader.load_file(WORKSHOP_PATH).spec.data.get("encounters") as Array
	var occupancy := encounters.filter(
		func(value: Variant) -> bool:
			return String((value as Dictionary).get("definition_id")) == "encounter_occupancy_dispute"
	)[0] as Dictionary

	assert_str(occupancy.get("id")).is_equal("workshop_occupancy_dispute")
	assert_array(occupancy.get("rule_object_ids") as Array).contains_exactly(["machine_disputed_workshop"])


func test_pickup_sensor_detects_player_layer_and_collects_on_contact() -> void:
	var root := Node2D.new()
	add_child(root)
	var pickup := DebugPickup.new()
	pickup.pickup_id = &"pickup_fixture"
	root.add_child(pickup)
	var collected_ids: Array[StringName] = []
	pickup.collected.connect(func(pickup_id: StringName) -> void: collected_ids.append(pickup_id))
	var player := PlayerController.new()

	assert_int(pickup.collision_layer).is_equal(0)
	assert_int(pickup.collision_mask).is_equal(2)
	pickup._on_body_entered(player)
	assert_bool(pickup.is_collected()).is_true()
	assert_bool(pickup.visible).is_false()
	assert_array(collected_ids).contains_exactly([&"pickup_fixture"])
	player.free()
	root.free()


func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.register_catalog(load(CATALOG_PATH) as ContentCatalog, CATALOG_PATH)
	return registry
