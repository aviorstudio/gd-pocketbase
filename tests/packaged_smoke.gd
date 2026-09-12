extends SceneTree

const AuthResponseModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/auth_response_module.gd"
)

func _init() -> void:
	var normalized: Dictionary[String, Variant] = AuthResponseModule.normalize({
		"token": "packaged-token", "record": {"id": "packaged-user"}
	})
	if normalized.access_token != "packaged-token" or normalized.user.id != "packaged-user":
		push_error("installed package smoke contract failed")
		quit(1)
		return
	print("TEST_SENTINEL:packaged_smoke.gd:2")
	quit()
