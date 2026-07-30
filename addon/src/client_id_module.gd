## Cross-platform stable client ID generation and persistence.
class_name PocketBaseClientIdModule
extends RefCounted

class ClientIdConfig extends RefCounted:
	var storage_key: String = "app_client_id"
	var prefix: String = "web_"

static func get_client_id(config: ClientIdConfig = null) -> String:
	if not OS.has_feature("web"):
		return OS.get_unique_id()
	var resolved: ClientIdConfig = config if config != null else ClientIdConfig.new()
	var existing: String = str(JavaScriptBridge.eval(
		"localStorage.getItem('%s')" % resolved.storage_key, true
	))
	if existing != "null" and not existing.is_empty():
		return existing
	var generated: String = str(JavaScriptBridge.eval(
		"(typeof crypto !== 'undefined' && crypto.randomUUID) ? crypto.randomUUID() : ''", true
	))
	if generated == "null" or generated.is_empty():
		generated = str(Time.get_ticks_msec()) + "_" + str(randi()) + "_" + str(randi())
	generated = resolved.prefix + generated
	JavaScriptBridge.eval(
		"localStorage.setItem('%s', '%s')" % [resolved.storage_key, generated], true
	)
	return generated
