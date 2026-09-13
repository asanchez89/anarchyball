class_name LevelPlaytestProfile
extends RefCounted

const SUPPORTED_LIFECYCLES: PackedStringArray = [
	"technical_prototype",
	"generated_draft",
	"curated_shipping",
]
const SUPPORTED_CLASSIFICATIONS: PackedStringArray = [
	"technical_prototype",
	"optional_challenge",
	"short_mission",
	"standard_mission",
	"climax_mission",
]
const REQUIRED_BEATS: PackedStringArray = [
	"introduce",
	"demonstrate",
	"challenge",
	"combine",
	"climax",
]
const SHIPPING_TARGET_FIELDS: PackedStringArray = [
	"first_clear_seconds",
	"clean_replay_seconds",
	"completionist_seconds",
	"effective_route_screens",
	"checkpoint_interval_seconds",
]


static func load_and_validate(path: String, known_level_ids: PackedStringArray = PackedStringArray()) -> Dictionary:
	var result := {"data": {}, "errors": PackedStringArray()}
	if not FileAccess.file_exists(path):
		(result["errors"] as PackedStringArray).append("%s: el archivo no existe" % path)
		return result
	var parser := JSON.new()
	var parse_error := parser.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK or not parser.data is Dictionary:
		(result["errors"] as PackedStringArray).append("%s: JSON inválido" % path)
		return result
	result["data"] = parser.data as Dictionary
	result["errors"] = validate(parser.data as Dictionary, path, known_level_ids)
	return result


static func validate(
	data: Dictionary,
	source: String = "<profile>",
	known_level_ids: PackedStringArray = PackedStringArray()
) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(data.get("schema_version", -1)) != 0:
		errors.append("%s.schema_version: se esperaba 0" % source)
	var level_id := StringName(String(data.get("level_id", "")))
	if not ContentId.is_valid(level_id):
		errors.append("%s.level_id: debe ser un ID estable snake_case" % source)
	elif not known_level_ids.is_empty() and String(level_id) not in known_level_ids:
		errors.append("%s.level_id: no existe un LevelSpec asociado" % source)
	var lifecycle := String(data.get("lifecycle", ""))
	if lifecycle not in SUPPORTED_LIFECYCLES:
		errors.append("%s.lifecycle: valor no soportado" % source)
	var classification := String(data.get("classification", ""))
	if classification not in SUPPORTED_CLASSIFICATIONS:
		errors.append("%s.classification: valor no soportado" % source)
	var beats := data.get("beats", []) as Array
	for beat: String in REQUIRED_BEATS:
		if beat not in beats:
			errors.append("%s.beats: falta '%s'" % [source, beat])
	var evidence_targets := data.get("evidence_targets", {}) as Dictionary
	if int(evidence_targets.get("minimum_first_clear_samples", 0)) < 3:
		errors.append("%s.evidence_targets.minimum_first_clear_samples: mínimo 3" % source)
	if int(evidence_targets.get("minimum_clean_replay_samples", 0)) < 3:
		errors.append("%s.evidence_targets.minimum_clean_replay_samples: mínimo 3" % source)
	if lifecycle == "technical_prototype":
		if classification != "technical_prototype":
			errors.append("%s.classification: un prototipo técnico no es una misión de campaña" % source)
		var decision := data.get("decision", {}) as Dictionary
		if String(decision.get("action", "")) != "retain_as_prototype":
			errors.append("%s.decision.action: debe conservar explícitamente el prototipo" % source)
		var successor_id := StringName(String(data.get("campaign_successor_id", "")))
		if not ContentId.is_valid(successor_id) or successor_id == level_id:
			errors.append("%s.campaign_successor_id: debe identificar un nivel futuro diferente" % source)
	else:
		var targets := data.get("targets", {}) as Dictionary
		for field: String in SHIPPING_TARGET_FIELDS:
			_validate_range(targets, field, source, errors)
	return errors


static func _validate_range(
	targets: Dictionary,
	field: String,
	source: String,
	errors: PackedStringArray
) -> void:
	var value: Variant = targets.get(field)
	if not value is Array or (value as Array).size() != 2:
		errors.append("%s.targets.%s: se requiere rango [mínimo, máximo]" % [source, field])
		return
	var range_values := value as Array
	if float(range_values[0]) < 0.0 or float(range_values[1]) <= float(range_values[0]):
		errors.append("%s.targets.%s: rango inválido" % [source, field])
