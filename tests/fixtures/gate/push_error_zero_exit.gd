extends SceneTree

func _init() -> void:
	push_error("synthetic runtime error followed by zero exit")
	print("TEST_SENTINEL:push_error_zero_exit.gd:1")
	quit()
