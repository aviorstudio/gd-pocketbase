## Normalizes native PocketBase and trusted backend-proxy auth responses.
class_name PocketBaseAuthResponseModule
extends RefCounted

static func normalize(response: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var token: String = str(response.get("access_token", response.get("token", "")))
	var raw_user: Variant = response.get("user", response.get("record", {}))
	var user: Dictionary[String, Variant] = {}
	if raw_user is Dictionary:
		user.merge(raw_user)
	return {
		"access_token": token,
		"user": {
			"id": str(user.get("id", "")),
			"email": str(user.get("email", "")),
			"username": str(user.get("username", ""))
		}
	}
