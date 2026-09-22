class_name CrewCoordinationDefinition
extends Resource

@export var content_id: StringName
@export var terminal_positions: PackedVector2Array = []
@export var platform_ids: Array[StringName] = []
@export var power_object_id: StringName
@export var interrupting_encounter_id: StringName


func validation_errors(spec: LevelSpec) -> Array[String]:
	var errors: Array[String] = []
	if not ContentId.is_valid(content_id) or terminal_positions.size() != 2 or platform_ids.size() != 2:
		errors.append("coordination requires stable id, two terminals and two platform targets")
	for id: StringName in platform_ids:
		if not (spec.data.get("platforms", []) as Array).any(func(v: Dictionary) -> bool: return String(v.id) == String(id)):
			errors.append("unknown coordination platform: " + String(id))
	if platform_ids.size() == 2 and platform_ids[0] == platform_ids[1]:
		errors.append("coordination targets must be independent")
	if not (spec.data.get("rule_objects", []) as Array).any(func(v: Dictionary) -> bool: return String(v.id) == String(power_object_id)):
		errors.append("unknown coordination power source")
	if not (spec.data.get("encounters", []) as Array).any(func(v: Dictionary) -> bool: return String(v.id) == String(interrupting_encounter_id)):
		errors.append("unknown coordination interrupter")
	for point: Vector2 in terminal_positions:
		if point.x < 0 or point.y < 0 or point.x > float(spec.data.bounds.width) or point.y > float(spec.data.bounds.height):
			errors.append("coordination terminal outside bounds")
	return errors
