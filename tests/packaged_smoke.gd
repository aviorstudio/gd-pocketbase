extends SceneTree

const AuthResponseModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/auth_response_module.gd"
)
const ClientIdModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/client_id_module.gd"
)
const CredentialAdapter = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/credential_adapter.gd"
)
const JwtModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/jwt_module.gd"
)
const SessionStoreModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/session_store_module.gd"
)

class FakeAdapter extends CredentialAdapter:
	var values: Dictionary[String, String] = {}

	func read_value(key: String) -> Result:
		return Result.new(Status.OK, values[key]) if values.has(key) else Result.new(Status.NOT_FOUND)

	func write_value(key: String, value: String) -> Result:
		values[key] = value
		return Result.new(Status.OK)

func _init() -> void:
	var normalized: Dictionary[String, Variant] = AuthResponseModule.normalize({
		"token": "packaged-token", "record": {"id": "packaged-user"}
	})
	var adapter: FakeAdapter = FakeAdapter.new()
	var store_config: SessionStoreModule.SessionStoreConfig = SessionStoreModule.SessionStoreConfig.new()
	store_config.native_adapter = adapter
	var store: SessionStoreModule = SessionStoreModule.new(store_config)
	var saved: SessionStoreModule.Result = store.save(normalized)
	var loaded: SessionStoreModule.Result = store.load_session()
	var client_config: ClientIdModule.ClientIdConfig = ClientIdModule.ClientIdConfig.new()
	client_config.native_adapter = adapter
	var client_id: ClientIdModule.Result = ClientIdModule.get_client_id(client_config)
	var jwt: JwtModule.JwtMetadata = JwtModule.inspect_expiry(_build_jwt({"exp": 200}), 100)
	if (
		normalized.access_token != "packaged-token"
		or normalized.user.id != "packaged-user"
		or not saved.is_ok()
		or not loaded.is_ok()
		or loaded.data.access_token != "packaged-token"
		or not client_id.is_ok()
		or jwt.status != JwtModule.Status.VALID
		or not jwt.untrusted
	):
		push_error("installed package smoke contract failed")
		quit(1)
		return
	print("TEST_SENTINEL:packaged_smoke.gd:8")
	quit()

func _build_jwt(claims: Dictionary[String, Variant]) -> String:
	var header: String = _base64url(JSON.stringify({"alg": "HS256"}).to_utf8_buffer())
	var payload: String = _base64url(JSON.stringify(claims).to_utf8_buffer())
	return "%s.%s.signature" % [header, payload]

func _base64url(raw: PackedByteArray) -> String:
	var encoded: String = Marshalls.raw_to_base64(raw).replace("+", "-").replace("/", "_")
	return encoded.trim_suffix("=").trim_suffix("=")
