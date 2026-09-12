extends SceneTree

const ClientIdModule = preload("res://addon/src/client_id_module.gd")
const CredentialAdapter = preload("res://addon/src/credential_adapter.gd")

class FakeAdapter extends CredentialAdapter:
	var values: Dictionary[String, String] = {}
	var fail_write: bool = false
	var corrupt_after_write: bool = false

	func read_value(key: String) -> Result:
		if not values.has(key):
			return Result.new(Status.NOT_FOUND)
		return Result.new(Status.OK, values[key])

	func write_value(key: String, value: String) -> Result:
		if fail_write:
			return Result.new(Status.IO_ERROR, "", "synthetic failure")
		values[key] = "different" if corrupt_after_write else value
		return Result.new(Status.OK)

var _assertions: int = 0

func _init() -> void:
	_assert(ClientIdModule.get_client_id().status == ClientIdModule.Status.UNAVAILABLE, "native adapter should be required")
	var adapter: FakeAdapter = FakeAdapter.new()
	var config: ClientIdModule.ClientIdConfig = ClientIdModule.ClientIdConfig.new()
	config.native_adapter = adapter
	config.storage_key = "quotes'\"\nslashes/../remain-data"
	config.prefix = "native_"
	var first: ClientIdModule.Result = ClientIdModule.get_client_id(config)
	var second: ClientIdModule.Result = ClientIdModule.get_client_id(config)
	_assert(first.is_ok() and first.client_id.begins_with("native_"), "adapter client ID should generate")
	_assert(second.client_id == first.client_id, "adapter client ID should be stable")
	_assert(adapter.values.keys()[0].contains("quotes'\"\nslashes/../remain-data"), "key must remain data without interpolation")

	var failed_config: ClientIdModule.ClientIdConfig = ClientIdModule.ClientIdConfig.new()
	var failed_adapter: FakeAdapter = FakeAdapter.new()
	failed_adapter.fail_write = true
	failed_config.native_adapter = failed_adapter
	_assert(ClientIdModule.get_client_id(failed_config).status == ClientIdModule.Status.IO_ERROR, "write failure should be typed")
	failed_adapter.fail_write = false
	failed_adapter.corrupt_after_write = true
	_assert(ClientIdModule.get_client_id(failed_config).status == ClientIdModule.Status.READBACK_FAILED, "partial/interleaved write should fail readback")
	failed_config.storage_key = "x".repeat(ClientIdModule.MAX_KEY_BYTES + 1)
	_assert(ClientIdModule.get_client_id(failed_config).status == ClientIdModule.Status.INVALID_CONFIG, "oversized key should fail")

	print("TEST_SENTINEL:client_id_module_test.gd:%d" % _assertions)
	quit()

func _assert(condition: bool, message: String) -> void:
	_assertions += 1
	if condition:
		return
	push_error(message)
	quit(1)
