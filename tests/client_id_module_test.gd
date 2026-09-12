extends SceneTree

const ClientIdModule = preload("res://addon/src/client_id_module.gd")

func _init() -> void:
	var assertion_count: int = 0
	if not OS.has_feature("web"):
		var first: String = ClientIdModule.get_client_id()
		var second: String = ClientIdModule.get_client_id()
		_assert(not first.is_empty(), "native client ID should not be empty")
		assertion_count += 1
		_assert(first == second, "native client ID should be stable")
		assertion_count += 1
	print("TEST_SENTINEL:client_id_module_test.gd:%d" % assertion_count)
	quit()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
