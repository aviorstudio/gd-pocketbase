extends SceneTree

const CredentialAdapter = preload("res://addon/src/credential_adapter.gd")
const SessionStoreModule = preload("res://addon/src/session_store_module.gd")

class FakeAdapter extends CredentialAdapter:
	var values: Dictionary[String, String] = {}
	var fail_write: bool = false
	var corrupt_after_write: String = ""

	func read_value(key: String) -> Result:
		if not values.has(key):
			return Result.new(Status.NOT_FOUND)
		return Result.new(Status.OK, values[key])

	func write_value(key: String, value: String) -> Result:
		if fail_write:
			return Result.new(Status.IO_ERROR, "", "synthetic write failure")
		values[key] = corrupt_after_write if not corrupt_after_write.is_empty() else value
		return Result.new(Status.OK)

var _assertions: int = 0

func _init() -> void:
	var unavailable: SessionStoreModule = SessionStoreModule.new()
	_assert(unavailable.load_session().status == SessionStoreModule.Status.UNAVAILABLE, "native adapter must be required")

	var adapter: FakeAdapter = FakeAdapter.new()
	var config: SessionStoreModule.SessionStoreConfig = _config("primary", adapter)
	var store: SessionStoreModule = SessionStoreModule.new(config)
	_assert(store.load_session().status == SessionStoreModule.Status.NOT_FOUND, "new store should be empty")
	_assert(store.save({"access_token": "token", "user_id": "user-1"}).is_ok(), "session should save")
	var loaded: SessionStoreModule.Result = store.load_session()
	_assert(loaded.is_ok() and loaded.data.access_token == "token", "session should load")

	var previous: String = adapter.values.values()[0]
	adapter.fail_write = true
	_assert(store.save({"access_token": "replacement"}).status == SessionStoreModule.Status.IO_ERROR, "write failure should be typed")
	_assert(adapter.values.values()[0] == previous, "failed atomic adapter write should preserve committed data")
	adapter.fail_write = false
	adapter.corrupt_after_write = '{"version":1,"state":"active","data":{"access_token":"other-complete-writer"}}'
	_assert(store.save({"access_token": "contended"}).status == SessionStoreModule.Status.READBACK_FAILED, "interleaved writer should fail readback")
	_assert(store.load_session().data.access_token == "other-complete-writer", "concurrent last completed write should remain complete")
	adapter.corrupt_after_write = ""
	adapter.values[adapter.values.keys()[0]] = "not-json"
	_assert(store.load_session().status == SessionStoreModule.Status.CORRUPT, "corrupt destination should be typed and retained")
	adapter.values.clear()

	var deep: Variant = "leaf"
	for _depth: int in 17:
		deep = [deep]
	_assert(store.save({"deep": deep}).status == SessionStoreModule.Status.INVALID_DATA, "depth above 16 should fail")
	_assert(store.save({"large": "x".repeat(SessionStoreModule.MAX_SESSION_BYTES)}).status == SessionStoreModule.Status.TOO_LARGE, "session above 64 KiB should fail")
	var unsafe_store: SessionStoreModule = SessionStoreModule.new(_config("../escape", adapter))
	_assert(unsafe_store.save({"a": 1}).status == SessionStoreModule.Status.INVALID_CONFIG, "unsafe store id should fail")

	var legacy_path: String = "user://legacy_%d.json" % Time.get_ticks_usec()
	_write_legacy(legacy_path, {"access_token": "legacy-token"})
	var migration_adapter: FakeAdapter = FakeAdapter.new()
	var migration_config: SessionStoreModule.SessionStoreConfig = _config("migration", migration_adapter)
	migration_config.legacy_paths = [legacy_path]
	var migration_store: SessionStoreModule = SessionStoreModule.new(migration_config)
	var migrated: SessionStoreModule.Result = migration_store.load_session()
	_assert(migrated.is_ok() and migrated.data.access_token == "legacy-token", "legacy session should migrate after verified write")
	_assert(migrated.migrated_from == legacy_path, "migration should report its source")
	_assert(FileAccess.file_exists(legacy_path), "verified migration must retain legacy source")
	_assert(migration_store.clear().is_ok(), "logout tombstone should commit")
	_assert(migration_store.load_session().status == SessionStoreModule.Status.NOT_FOUND, "logout must not remigrate retained legacy data")
	_assert(FileAccess.file_exists(legacy_path), "logout must retain legacy source under nondestructive policy")

	var failing_adapter: FakeAdapter = FakeAdapter.new()
	failing_adapter.fail_write = true
	var failing_config: SessionStoreModule.SessionStoreConfig = _config("migration_failure", failing_adapter)
	failing_config.legacy_paths = [legacy_path]
	var failed_migration: SessionStoreModule.Result = SessionStoreModule.new(failing_config).load_session()
	_assert(failed_migration.status == SessionStoreModule.Status.MIGRATION_FAILED, "migration write failure should be typed")
	_assert(FileAccess.file_exists(legacy_path), "failed migration must retain legacy source")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
	print("TEST_SENTINEL:session_store_module_test.gd:%d" % _assertions)
	quit()

func _config(store_id: String, adapter: FakeAdapter) -> SessionStoreModule.SessionStoreConfig:
	var config: SessionStoreModule.SessionStoreConfig = SessionStoreModule.SessionStoreConfig.new()
	config.store_id = store_id
	config.native_adapter = adapter
	return config

func _write_legacy(path: String, data: Dictionary[String, Variant]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	_assert(file != null, "legacy fixture should open")
	file.store_string(JSON.stringify(data))
	file.close()

func _assert(condition: bool, message: String) -> void:
	_assertions += 1
	if condition:
		return
	push_error(message)
	quit(1)
