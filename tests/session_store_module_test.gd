extends SceneTree

const SessionStoreModule = preload("res://addon/src/session_store_module.gd")

func _init() -> void:
	var config: SessionStoreModule.SessionStoreConfig = SessionStoreModule.SessionStoreConfig.new()
	config.store_id = "test_%d" % Time.get_ticks_msec()
	var store: SessionStoreModule = SessionStoreModule.new(config)
	store.clear()
	_assert(store.save({"access_token": "token", "user_id": "user-1"}), "session should save")
	var loaded: Dictionary[String, Variant] = store.load_session()
	_assert(loaded.access_token == "token", "session should load")
	_assert(store.exists(), "saved session should exist")
	store.clear()
	_assert(not store.exists(), "cleared session should not exist")
	quit()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
