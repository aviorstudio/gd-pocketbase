extends SceneTree

const JwtModule = preload("res://addon/src/jwt_module.gd")

func _init() -> void:
	var expiry: int = int(Time.get_unix_time_from_system()) + 120
	var token: String = _build_jwt({
		"sub": "user-1", "email": "player@example.com", "exp": expiry, "iat": expiry - 60
	})
	var payload: JwtModule.JwtPayload = JwtModule.decode_payload(token)
	_assert(payload.subject == "user-1", "subject should decode")
	_assert(payload.email == "player@example.com", "email should decode")
	_assert(JwtModule.get_expiry_unix(token) == expiry, "expiry should decode")
	_assert(not JwtModule.is_expired(token, expiry - 1), "token should be active before exp")
	_assert(JwtModule.is_expired(token, expiry), "token should expire at exp")
	quit()

func _build_jwt(claims: Dictionary[String, Variant]) -> String:
	var header: String = _to_base64url(JSON.stringify({"alg": "HS256"}).to_utf8_buffer())
	var payload: String = _to_base64url(JSON.stringify(claims).to_utf8_buffer())
	return "%s.%s.signature" % [header, payload]

func _to_base64url(raw: PackedByteArray) -> String:
	var encoded: String = Marshalls.raw_to_base64(raw).replace("+", "-").replace("/", "_")
	while encoded.ends_with("="):
		encoded = encoded.left(-1)
	return encoded

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
