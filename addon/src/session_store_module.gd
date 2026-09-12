## Bounded session persistence through an injected native credential adapter or
## process memory on web. Legacy plaintext sources are retained after migration.
class_name PocketBaseSessionStoreModule
extends RefCounted

const CredentialAdapter = preload("credential_adapter.gd")
const MAX_SESSION_BYTES: int = 64 * 1024
const MAX_JSON_DEPTH: int = 16
const MAX_STORE_ID_BYTES: int = 64

enum Status {
	OK,
	NOT_FOUND,
	UNAVAILABLE,
	INVALID_CONFIG,
	INVALID_DATA,
	TOO_LARGE,
	IO_ERROR,
	CORRUPT,
	READBACK_FAILED,
	MIGRATION_FAILED,
}

class Result extends RefCounted:
	var status: Status = Status.UNAVAILABLE
	var data: Dictionary[String, Variant] = {}
	var detail: String = ""
	var migrated_from: String = ""

	func _init(resolved_status: Status, resolved_detail: String = "") -> void:
		status = resolved_status
		detail = resolved_detail

	func is_ok() -> bool:
		return status == Status.OK

class SessionStoreConfig extends RefCounted:
	var store_id: String = "default"
	var legacy_paths: Array[String] = []
	var native_adapter: CredentialAdapter = null

var _config: SessionStoreConfig = SessionStoreConfig.new()
var _adapter: CredentialAdapter = null

func _init(config: SessionStoreConfig = null) -> void:
	if config != null:
		_config = config
	if OS.has_feature("web"):
		_adapter = CredentialAdapter.WebMemoryAdapter.new()
	else:
		_adapter = _config.native_adapter

func save(data: Dictionary[String, Variant]) -> Result:
	var configuration_error: Result = _validate_config()
	if configuration_error != null:
		return configuration_error
	if data.is_empty():
		return clear()
	var seen: Array[Variant] = []
	if not _is_json_compatible(data, 1, seen):
		return Result.new(Status.INVALID_DATA, "session must be acyclic JSON-compatible data with depth <= 16")
	var encoded: String = JSON.stringify({"version": 1, "state": "active", "data": data})
	if encoded.to_utf8_buffer().size() > MAX_SESSION_BYTES:
		return Result.new(Status.TOO_LARGE, "encoded session exceeds 65536 bytes")
	return _write_verified(encoded, Status.READBACK_FAILED)

func load_session() -> Result:
	var configuration_error: Result = _validate_config()
	if configuration_error != null:
		return configuration_error
	if _adapter == null:
		return Result.new(Status.UNAVAILABLE, "native credential adapter is required")
	var stored: CredentialAdapter.Result = _adapter.read_value(_storage_key())
	if stored.status == CredentialAdapter.Status.OK:
		return _decode_envelope(stored.value)
	if stored.status != CredentialAdapter.Status.NOT_FOUND:
		return _map_adapter_error(stored)
	return _migrate_legacy()

func clear() -> Result:
	var configuration_error: Result = _validate_config()
	if configuration_error != null:
		return configuration_error
	# A verified tombstone prevents retained legacy data from being remigrated
	# after logout while honoring the nondestructive migration policy.
	return _write_verified(JSON.stringify({"version": 1, "state": "cleared"}), Status.READBACK_FAILED)

func _write_verified(encoded: String, mismatch_status: Status) -> Result:
	if _adapter == null:
		return Result.new(Status.UNAVAILABLE, "native credential adapter is required")
	var written: CredentialAdapter.Result = _adapter.write_value(_storage_key(), encoded)
	if not written.is_ok():
		return _map_adapter_error(written)
	var readback: CredentialAdapter.Result = _adapter.read_value(_storage_key())
	if not readback.is_ok() or readback.value != encoded:
		return Result.new(mismatch_status, "credential destination commit did not pass readback")
	return Result.new(Status.OK)

func _decode_envelope(encoded: String) -> Result:
	if encoded.to_utf8_buffer().size() > MAX_SESSION_BYTES:
		return Result.new(Status.TOO_LARGE, "stored session exceeds 65536 bytes")
	var json: JSON = JSON.new()
	if json.parse(encoded) != OK:
		return Result.new(Status.CORRUPT, "stored session envelope is invalid JSON")
	var parsed: Variant = json.data
	if not (parsed is Dictionary) or parsed.get("version") != 1:
		return Result.new(Status.CORRUPT, "stored session envelope is invalid")
	if parsed.get("state") == "cleared":
		return Result.new(Status.NOT_FOUND)
	if parsed.get("state") != "active" or not (parsed.get("data") is Dictionary):
		return Result.new(Status.CORRUPT, "stored session envelope has invalid state or data")
	var seen: Array[Variant] = []
	if not _is_json_compatible(parsed.data, 1, seen):
		return Result.new(Status.CORRUPT, "stored session exceeds JSON depth or type contract")
	var result: Result = Result.new(Status.OK)
	result.data.merge(parsed.data)
	return result

func _migrate_legacy() -> Result:
	for path: String in _config.legacy_paths:
		if FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file == null:
				return Result.new(Status.IO_ERROR, "legacy session could not be opened")
			if file.get_length() > MAX_SESSION_BYTES:
				return Result.new(Status.TOO_LARGE, "legacy session exceeds 65536 bytes")
			var json: JSON = JSON.new()
			if json.parse(file.get_as_text()) != OK:
				return Result.new(Status.CORRUPT, "legacy session is invalid JSON")
			var parsed: Variant = json.data
			if not (parsed is Dictionary):
				return Result.new(Status.CORRUPT, "legacy session is invalid JSON")
			var payload: Dictionary[String, Variant] = {}
			payload.merge(parsed)
			var saved: Result = save(payload)
			if not saved.is_ok():
				var failed: Result = Result.new(Status.MIGRATION_FAILED, saved.detail)
				failed.migrated_from = path
				return failed
			var migrated: Result = load_session()
			if migrated.is_ok():
				migrated.migrated_from = path
			return migrated
	return Result.new(Status.NOT_FOUND)

func _validate_config() -> Result:
	var bytes: PackedByteArray = _config.store_id.to_utf8_buffer()
	if bytes.is_empty() or bytes.size() > MAX_STORE_ID_BYTES:
		return Result.new(Status.INVALID_CONFIG, "store_id must contain 1 to 64 ASCII-safe bytes")
	for byte: int in bytes:
		var allowed: bool = (
			(byte >= 65 and byte <= 90)
			or (byte >= 97 and byte <= 122)
			or (byte >= 48 and byte <= 57)
			or byte == 45
			or byte == 46
			or byte == 95
		)
		if not allowed:
			return Result.new(Status.INVALID_CONFIG, "store_id contains an unsafe character")
	for path: String in _config.legacy_paths:
		if not path.begins_with("user://"):
			return Result.new(Status.INVALID_CONFIG, "legacy paths must use user://")
	return null

func _storage_key() -> String:
	return "gd-pocketbase/session/%s" % _config.store_id

func _map_adapter_error(adapter_result: CredentialAdapter.Result) -> Result:
	if adapter_result.status == CredentialAdapter.Status.NOT_FOUND:
		return Result.new(Status.NOT_FOUND, adapter_result.detail)
	if adapter_result.status == CredentialAdapter.Status.UNAVAILABLE:
		return Result.new(Status.UNAVAILABLE, adapter_result.detail)
	if adapter_result.status == CredentialAdapter.Status.INVALID_ARGUMENT:
		return Result.new(Status.INVALID_CONFIG, adapter_result.detail)
	return Result.new(Status.IO_ERROR, adapter_result.detail)

func _is_json_compatible(value: Variant, depth: int, seen: Array[Variant]) -> bool:
	if depth > MAX_JSON_DEPTH:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY, TYPE_DICTIONARY:
			for ancestor: Variant in seen:
				if is_same(ancestor, value):
					return false
			seen.append(value)
			if value is Array:
				for item: Variant in value:
					if not _is_json_compatible(item, depth + 1, seen):
						seen.pop_back()
						return false
			else:
				for key: Variant in value:
					if not (key is String) or not _is_json_compatible(value[key], depth + 1, seen):
						seen.pop_back()
						return false
			seen.pop_back()
			return true
	return false
