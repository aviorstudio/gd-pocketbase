## Random client ID generation through the selected persistence adapter.
class_name PocketBaseClientIdModule
extends RefCounted

const CredentialAdapter = preload("credential_adapter.gd")
const MAX_KEY_BYTES: int = 128
const MAX_PREFIX_BYTES: int = 64
const MAX_ID_BYTES: int = 256

enum Status {
	OK,
	UNAVAILABLE,
	INVALID_CONFIG,
	IO_ERROR,
	READBACK_FAILED,
}

class Result extends RefCounted:
	var status: Status = Status.UNAVAILABLE
	var client_id: String = ""
	var detail: String = ""

	func _init(resolved_status: Status, resolved_id: String = "", resolved_detail: String = "") -> void:
		status = resolved_status
		client_id = resolved_id
		detail = resolved_detail

	func is_ok() -> bool:
		return status == Status.OK

class ClientIdConfig extends RefCounted:
	var storage_key: String = "app_client_id"
	var prefix: String = "client_"
	var native_adapter: CredentialAdapter = null

static func get_client_id(config: ClientIdConfig = null) -> Result:
	var resolved: ClientIdConfig = config if config != null else ClientIdConfig.new()
	var key_size: int = resolved.storage_key.to_utf8_buffer().size()
	if key_size == 0 or key_size > MAX_KEY_BYTES or resolved.prefix.to_utf8_buffer().size() > MAX_PREFIX_BYTES:
		return Result.new(Status.INVALID_CONFIG, "storage_key must be 1..128 bytes and prefix <= 64 bytes")
	var adapter: CredentialAdapter = (
		CredentialAdapter.WebMemoryAdapter.new() if OS.has_feature("web") else resolved.native_adapter
	)
	if adapter == null:
		return Result.new(Status.UNAVAILABLE, "native credential adapter is required")
	var storage_key: String = "gd-pocketbase/client-id/%s" % resolved.storage_key
	var existing: CredentialAdapter.Result = adapter.read_value(storage_key)
	if existing.status == CredentialAdapter.Status.OK:
		if existing.value.is_empty() or existing.value.to_utf8_buffer().size() > MAX_ID_BYTES:
			return Result.new(Status.IO_ERROR, "stored client ID is invalid")
		return Result.new(Status.OK, existing.value)
	if existing.status != CredentialAdapter.Status.NOT_FOUND:
		return _adapter_error(existing)
	var generated: String = resolved.prefix + _random_identifier()
	if generated.to_utf8_buffer().size() > MAX_ID_BYTES:
		return Result.new(Status.INVALID_CONFIG, "generated client ID exceeds 256 bytes")
	var written: CredentialAdapter.Result = adapter.write_value(storage_key, generated)
	if not written.is_ok():
		return _adapter_error(written)
	var readback: CredentialAdapter.Result = adapter.read_value(storage_key)
	if not readback.is_ok() or readback.value != generated:
		return Result.new(Status.READBACK_FAILED, "", "client ID destination commit did not pass readback")
	return Result.new(Status.OK, generated)

static func _random_identifier() -> String:
	if OS.has_feature("web"):
		var crypto: JavaScriptObject = JavaScriptBridge.get_interface("crypto")
		if crypto != null and "randomUUID" in crypto:
			var uuid: String = str(crypto.randomUUID())
			if not uuid.is_empty() and uuid != "null":
				return uuid
	var random_bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	return random_bytes.hex_encode()

static func _adapter_error(adapter_result: CredentialAdapter.Result) -> Result:
	if adapter_result.status == CredentialAdapter.Status.UNAVAILABLE:
		return Result.new(Status.UNAVAILABLE, "", adapter_result.detail)
	if adapter_result.status == CredentialAdapter.Status.INVALID_ARGUMENT:
		return Result.new(Status.INVALID_CONFIG, "", adapter_result.detail)
	return Result.new(Status.IO_ERROR, "", adapter_result.detail)
