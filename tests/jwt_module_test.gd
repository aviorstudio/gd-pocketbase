extends SceneTree

const JwtModule = preload("res://addon/src/jwt_module.gd")

var _assertions: int = 0

func _init() -> void:
	var active: JwtModule.JwtMetadata = JwtModule.inspect_expiry(_build_jwt({
		"sub": "user-1", "email": "player@example.com", "exp": 200, "iat": 100
	}), 150)
	_assert(active.status == JwtModule.Status.VALID, "valid metadata should be active")
	_assert(active.untrusted, "decoded metadata must be explicitly untrusted")
	_assert(active.subject == "user-1" and active.email == "player@example.com", "metadata should decode")
	_assert(active.expires_at == 200 and active.issued_at == 100, "numeric dates should decode")
	_assert(JwtModule.inspect_expiry(_build_jwt({"exp": 200}), 200).status == JwtModule.Status.EXPIRED, "exp boundary should be expired")
	_assert(JwtModule.inspect_expiry(_build_jwt({"exp": 200}), 199, 1).status == JwtModule.Status.EXPIRED, "explicit skew should apply")
	_assert(JwtModule.inspect_expiry(_build_jwt({"exp": 200, "sub": "玩家"}), 100).subject == "玩家", "Unicode metadata should decode")

	_assert_invalid("token", JwtModule.ErrorCode.MALFORMED_TOKEN)
	_assert_invalid(".payload.signature", JwtModule.ErrorCode.MALFORMED_TOKEN)
	_assert_invalid("header.payload.", JwtModule.ErrorCode.MALFORMED_TOKEN)
	_assert_invalid("a.%%%25.c", JwtModule.ErrorCode.INVALID_BASE64URL)
	_assert_invalid(_build_raw_payload("not-json"), JwtModule.ErrorCode.INVALID_JSON)
	_assert_invalid(_build_jwt({"sub": "missing"}), JwtModule.ErrorCode.MISSING_EXP)
	for invalid_exp: Variant in [null, false, "200", 0, -1, 1.5]:
		_assert_invalid(_build_jwt({"exp": invalid_exp}), JwtModule.ErrorCode.INVALID_EXP)
	_assert_invalid(_build_raw_payload('{"exp":9223372036854775808}'), JwtModule.ErrorCode.INVALID_EXP)
	_assert_invalid(_build_jwt({"exp": 200}), JwtModule.ErrorCode.INVALID_SKEW, -1)
	_assert_invalid("a.%s.c" % "A".repeat(JwtModule.MAX_TOKEN_BYTES), JwtModule.ErrorCode.TOKEN_TOO_LARGE)
	var huge_claim: String = "x".repeat(JwtModule.MAX_PAYLOAD_BYTES + 1)
	_assert_invalid(_build_jwt({"exp": 200, "claim": huge_claim}), JwtModule.ErrorCode.PAYLOAD_TOO_LARGE)

	print("TEST_SENTINEL:jwt_module_test.gd:%d" % _assertions)
	quit()

func _assert_invalid(token: String, error: JwtModule.ErrorCode, skew: int = 0) -> void:
	var result: JwtModule.JwtMetadata = JwtModule.inspect_expiry(token, 100, skew)
	_assert(result.status == JwtModule.Status.INVALID, "token should be typed invalid")
	_assert(result.error == error, "invalid token should preserve the expected error")
	_assert(result.untrusted, "invalid metadata must remain explicitly untrusted")

func _build_jwt(claims: Dictionary[String, Variant]) -> String:
	return _build_raw_payload(JSON.stringify(claims))

func _build_raw_payload(payload_json: String) -> String:
	return _build_raw_bytes(payload_json.to_utf8_buffer())

func _build_raw_bytes(payload_bytes: PackedByteArray) -> String:
	var header: String = _to_base64url(JSON.stringify({"alg": "HS256"}).to_utf8_buffer())
	var payload: String = _to_base64url(payload_bytes)
	return "%s.%s.signature" % [header, payload]

func _to_base64url(raw: PackedByteArray) -> String:
	var encoded: String = Marshalls.raw_to_base64(raw).replace("+", "-").replace("/", "_")
	while encoded.ends_with("="):
		encoded = encoded.left(-1)
	return encoded

func _assert(condition: bool, message: String) -> void:
	_assertions += 1
	if condition:
		return
	push_error(message)
	quit(1)
