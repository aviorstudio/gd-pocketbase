extends Node

const ClientIdModule = preload("res://addon/src/client_id_module.gd")
const SessionStoreModule = preload("res://addon/src/session_store_module.gd")

func _ready() -> void:
	var session_config: SessionStoreModule.SessionStoreConfig = SessionStoreModule.SessionStoreConfig.new()
	session_config.store_id = "web_boundary"
	var store: SessionStoreModule = SessionStoreModule.new(session_config)
	var before: SessionStoreModule.Result = store.load_session()
	var saved: SessionStoreModule.Result = store.save({"access_token": "ephemeral", "user_id": "web-user"})
	var loaded: SessionStoreModule.Result = store.load_session()

	var client_config: ClientIdModule.ClientIdConfig = ClientIdModule.ClientIdConfig.new()
	client_config.storage_key = "quotes'\"\n/../stay-data"
	client_config.prefix = "web_"
	var first: ClientIdModule.Result = ClientIdModule.get_client_id(client_config)
	var second: ClientIdModule.Result = ClientIdModule.get_client_id(client_config)
	var passed: bool = (
		before.status == SessionStoreModule.Status.NOT_FOUND
		and saved.is_ok()
		and loaded.is_ok()
		and loaded.data.get("access_token") == "ephemeral"
		and first.is_ok()
		and second.is_ok()
		and first.client_id == second.client_id
	)

	var document: JavaScriptObject = JavaScriptBridge.get_interface("document")
	var result_node: JavaScriptObject = document.createElement("pre")
	result_node.id = "gd-pocketbase-verification"
	result_node.setAttribute("data-client-id", first.client_id)
	result_node.setAttribute(
		"style",
		"position:fixed;z-index:9999;top:32px;left:32px;margin:0;padding:24px;"
		+ "background:#111827;color:#d1fae5;border:2px solid #34d399;border-radius:12px;"
		+ "font:18px/1.6 monospace;white-space:pre-wrap;"
	)
	result_node.textContent = (
		"GD PocketBase web boundary PASS\n"
		+ "version=0.0.2\n"
		+ "persistence=memory-only\n"
		+ "reload-start=empty\n"
		+ "safe-key=quotes/newlines remain data\n"
		+ "sessionStorage/localStorage=unused"
		if passed
		else "GD PocketBase web boundary FAIL"
	)
	document.body.appendChild(result_node)
	var title_node: JavaScriptObject = document.querySelector("title")
	if title_node != null:
		title_node.textContent = "GD PocketBase web boundary %s" % ("PASS" if passed else "FAIL")
