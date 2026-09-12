## Bounded JWT metadata decoding. No signature or claim is verified here.
class_name PocketBaseJwtModule
extends RefCounted

const MAX_TOKEN_BYTES: int = 16 * 1024
const MAX_PAYLOAD_BYTES: int = 8 * 1024

enum Status {
	VALID,
	EXPIRED,
	INVALID,
}

enum ErrorCode {
	NONE,
	TOKEN_TOO_LARGE,
	MALFORMED_TOKEN,
	INVALID_BASE64URL,
	PAYLOAD_TOO_LARGE,
	INVALID_JSON,
	MISSING_EXP,
	INVALID_EXP,
	INVALID_SKEW,
}

class JwtMetadata extends RefCounted:
	var status: Status = Status.INVALID
	var error: ErrorCode = ErrorCode.MALFORMED_TOKEN
	var detail: String = ""
	## These fields are attacker-controlled metadata until a trusted server verifies the token.
	var untrusted: bool = true
	var subject: String = ""
	var email: String = ""
	var expires_at: int = 0
	var issued_at: int = 0
	var claims: Dictionary[String, Variant] = {}

static func inspect_expiry(token: String, now_unix: int = -1, skew_seconds: int = 0) -> JwtMetadata:
	var payload: JwtMetadata = JwtMetadata.new()
	if skew_seconds < 0:
		return _invalid(payload, ErrorCode.INVALID_SKEW, "skew_seconds must be nonnegative")
	if token.to_utf8_buffer().size() > MAX_TOKEN_BYTES:
		return _invalid(payload, ErrorCode.TOKEN_TOO_LARGE, "token exceeds 16384 bytes")
	var parts: PackedStringArray = token.split(".")
	if parts.size() != 3 or parts[1].is_empty():
		return _invalid(payload, ErrorCode.MALFORMED_TOKEN, "JWT must have three nonempty segments")
	if not _is_base64url(parts[1]):
		return _invalid(payload, ErrorCode.INVALID_BASE64URL, "payload is not canonical base64url")
	var payload_raw: PackedByteArray = Marshalls.base64_to_raw(_base64url_to_base64(parts[1]))
	if payload_raw.is_empty():
		return _invalid(payload, ErrorCode.INVALID_BASE64URL, "payload could not be decoded")
	if payload_raw.size() > MAX_PAYLOAD_BYTES:
		return _invalid(payload, ErrorCode.PAYLOAD_TOO_LARGE, "decoded payload exceeds 8192 bytes")
	var json: JSON = JSON.new()
	if json.parse(payload_raw.get_string_from_utf8()) != OK:
		return _invalid(payload, ErrorCode.INVALID_JSON, "payload is not valid JSON")
	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		return _invalid(payload, ErrorCode.INVALID_JSON, "payload JSON must be an object")
	payload.claims.merge(parsed)
	payload.subject = str(parsed.get("sub", ""))
	payload.email = str(parsed.get("email", ""))
	if not parsed.has("exp"):
		return _invalid(payload, ErrorCode.MISSING_EXP, "exp is required")
	var expiry: Variant = parsed.exp
	if not _is_positive_integral_numeric_date(expiry):
		return _invalid(payload, ErrorCode.INVALID_EXP, "exp must be a finite positive integral NumericDate")
	payload.expires_at = int(expiry)
	var issued: Variant = parsed.get("iat", 0)
	if _is_positive_integral_numeric_date(issued):
		payload.issued_at = int(issued)
	var now_seconds: int = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	payload.status = Status.EXPIRED if now_seconds >= payload.expires_at - skew_seconds else Status.VALID
	payload.error = ErrorCode.NONE
	payload.detail = ""
	return payload

static func _invalid(payload: JwtMetadata, code: ErrorCode, detail: String) -> JwtMetadata:
	payload.status = Status.INVALID
	payload.error = code
	payload.detail = detail
	return payload

static func _is_positive_integral_numeric_date(value: Variant) -> bool:
	if value is int:
		return value > 0
	if value is float:
		return is_finite(value) and value > 0.0 and value == floor(value) and value <= 9223372036854774784.0
	return false

static func _is_base64url(value: String) -> bool:
	if value.length() % 4 == 1:
		return false
	for index: int in value.length():
		var code: int = value.unicode_at(index)
		var allowed: bool = (
			(code >= 65 and code <= 90)
			or (code >= 97 and code <= 122)
			or (code >= 48 and code <= 57)
			or code == 45
			or code == 95
		)
		if not allowed:
			return false
	return true

static func _base64url_to_base64(value: String) -> String:
	var normalized: String = value.replace("-", "+").replace("_", "/")
	while normalized.length() % 4 != 0:
		normalized += "="
	return normalized
