class_name LevelSpecLoader
extends RefCounted


static func load_file(path: String) -> LevelSpecLoadResult:
	var result := LevelSpecLoadResult.new()
	if not FileAccess.file_exists(path):
		result.errors.append("%s: archivo: no existe" % path)
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.errors.append("%s: archivo: no se pudo abrir (error %s)" % [path, FileAccess.get_open_error()])
		return result
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		result.errors.append("%s:%d: JSON inválido: %s" % [path, json.get_error_line(), json.get_error_message()])
		return result
	if not json.data is Dictionary:
		result.errors.append("%s: raíz: se esperaba un objeto JSON" % path)
		return result
	result.spec = LevelSpec.new(json.data as Dictionary, path)
	return result
