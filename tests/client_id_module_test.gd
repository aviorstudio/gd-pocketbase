extends SceneTree

const ClientIdModule = preload("res://addon/src/client_id_module.gd")

func _init() -> void:
	if not OS.has_feature("web"):
		var first: String = ClientIdModule.get_client_id()
		var second: String = ClientIdModule.get_client_id()
		_assert(not first.is_empty(), "native client ID should not be empty")
		_assert(first == second, "native client ID should be stable")
	quit()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
