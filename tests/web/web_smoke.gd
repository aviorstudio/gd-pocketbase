extends Node

const AuthResponseModule = preload("res://addon/src/auth_response_module.gd")

func _ready() -> void:
	var normalized: Dictionary[String, Variant] = AuthResponseModule.normalize({
		"token": "web-token", "record": {"id": "web-user", "email": "w@example.com", "username": "w"}
	})
	var passed: bool = (
		normalized.access_token == "web-token"
		and normalized.user.id == "web-user"
		and normalized.user.email == "w@example.com"
	)

	var document: JavaScriptObject = JavaScriptBridge.get_interface("document")
	var result_node: JavaScriptObject = document.createElement("pre")
	result_node.id = "gd-pocketbase-verification"
	result_node.setAttribute(
		"style",
		"position:fixed;z-index:9999;top:32px;left:32px;margin:0;padding:24px;"
		+ "background:#111827;color:#d1fae5;border:2px solid #34d399;border-radius:12px;"
		+ "font:18px/1.6 monospace;white-space:pre-wrap;"
	)
	result_node.textContent = (
		"GD PocketBase web boundary PASS\n"
		+ "version=0.0.3\n"
		+ "normalize=native-and-proxy\n"
		+ "session-core=@aviorstudio/gd-session"
		if passed
		else "GD PocketBase web boundary FAIL"
	)
	document.body.appendChild(result_node)
	var title_node: JavaScriptObject = document.querySelector("title")
	if title_node != null:
		title_node.textContent = "GD PocketBase web boundary %s" % ("PASS" if passed else "FAIL")
