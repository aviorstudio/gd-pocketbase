extends SceneTree

const AuthResponseModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/auth_response_module.gd"
)

func _init() -> void:
	var native: Dictionary[String, Variant] = AuthResponseModule.normalize({
		"token": "packaged-token", "record": {"id": "packaged-user", "email": "p@example.com", "username": "p"}
	})
	var proxy: Dictionary[String, Variant] = AuthResponseModule.normalize({
		"access_token": "proxy-token", "user": {"id": "proxy-user"}
	})
	if (
		native.access_token != "packaged-token"
		or native.user.id != "packaged-user"
		or native.user.username != "p"
		or proxy.access_token != "proxy-token"
		or proxy.user.id != "proxy-user"
	):
		push_error("installed package smoke contract failed")
		quit(1)
		return
	print("TEST_SENTINEL:packaged_smoke.gd:5")
	quit()
