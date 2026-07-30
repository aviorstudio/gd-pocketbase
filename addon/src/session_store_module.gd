## File-backed session persistence with optional legacy path migration.
class_name PocketBaseSessionStoreModule
extends RefCounted

class SessionStoreConfig extends RefCounted:
	var file_path_template: String = "user://session_%s.dat"
	var store_id: String = "default"
	var legacy_paths: Array[String] = []

var _config: SessionStoreConfig = SessionStoreConfig.new()

func _init(config: SessionStoreConfig = null) -> void:
	if config != null:
		_config = config

func save(data: Dictionary[String, Variant]) -> bool:
	if data.is_empty():
		clear()
		return true
	var file: FileAccess = FileAccess.open(_get_primary_path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true

func load_session() -> Dictionary[String, Variant]:
	var resolved_path: String = _resolve_existing_path()
	if resolved_path.is_empty():
		return {}
	var file: FileAccess = FileAccess.open(resolved_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		clear()
		return {}
	var payload: Dictionary[String, Variant] = {}
	payload.merge(parsed)
	if resolved_path != _get_primary_path():
		save(payload)
		_remove_file(resolved_path)
	return payload

func clear() -> void:
	for path: String in _get_candidate_paths():
		if FileAccess.file_exists(path):
			_remove_file(path)

func exists() -> bool:
	for path: String in _get_candidate_paths():
		if FileAccess.file_exists(path):
			return true
	return false

func _get_primary_path() -> String:
	return _config.file_path_template % _config.store_id

func _get_candidate_paths() -> Array[String]:
	var candidates: Array[String] = [_get_primary_path()]
	for path: String in _config.legacy_paths:
		if not path.is_empty() and not candidates.has(path):
			candidates.append(path)
	return candidates

func _resolve_existing_path() -> String:
	for path: String in _get_candidate_paths():
		if FileAccess.file_exists(path):
			return path
	return ""

func _remove_file(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
