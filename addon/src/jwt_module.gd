## JWT helpers for payload decoding and expiry checks (no signature verification).
class_name PocketBaseJwtModule
extends RefCounted

class JwtPayload extends RefCounted:
	var subject: String = ""
	var email: String = ""
	var expires_at: int = 0
	var issued_at: int = 0
	var claims: Dictionary[String, Variant] = {}

static func decode_payload(token: String) -> JwtPayload:
	var payload: JwtPayload = JwtPayload.new()
	var parts: PackedStringArray = token.split(".")
	if parts.size() < 2:
		return payload
	var payload_raw: PackedByteArray = Marshalls.base64_to_raw(_base64url_to_base64(parts[1]))
	if payload_raw.is_empty():
		return payload
	var parsed: Variant = JSON.parse_string(payload_raw.get_string_from_utf8())
	if not (parsed is Dictionary):
		return payload
	payload.claims.merge(parsed)
	payload.subject = str(parsed.get("sub", ""))
	payload.email = str(parsed.get("email", ""))
	payload.expires_at = int(parsed.get("exp", 0))
	payload.issued_at = int(parsed.get("iat", 0))
	return payload

static func is_expired(token: String, now_unix: int = -1) -> bool:
	var expiry_unix: int = get_expiry_unix(token)
	if expiry_unix <= 0:
		return false
	var now_seconds: int = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	return now_seconds >= expiry_unix

static func get_expiry_unix(token: String) -> int:
	return decode_payload(token).expires_at

static func _base64url_to_base64(value: String) -> String:
	var normalized: String = value.replace("-", "+").replace("_", "/")
	while normalized.length() % 4 != 0:
		normalized += "="
	return normalized
