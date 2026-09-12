extends SceneTree

const AuthResponseModule = preload("res://addon/src/auth_response_module.gd")

func _init() -> void:
	var assertion_count: int = 0
	var native: Dictionary[String, Variant] = AuthResponseModule.normalize({
		"token": "native-token",
		"record": {"id": "user-1", "email": "one@example.com", "username": "one"}
	})
	_assert(native.access_token == "native-token", "native token should normalize")
	assertion_count += 1
	_assert(native.user.id == "user-1", "native record should normalize")
	assertion_count += 1

	var proxy: Dictionary[String, Variant] = AuthResponseModule.normalize({
		"access_token": "proxy-token",
		"user": {"id": "user-2", "email": "two@example.com", "username": "two"}
	})
	_assert(proxy.access_token == "proxy-token", "proxy token should normalize")
	assertion_count += 1
	_assert(proxy.user.username == "two", "proxy user should normalize")
	assertion_count += 1
	print("TEST_SENTINEL:auth_response_module_test.gd:%d" % assertion_count)
	quit()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
