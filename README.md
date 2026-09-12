# gd-pocketbase

PocketBase-friendly auth and bounded session primitives for Godot 4.

The addon provides unverified JWT expiry hints, caller-selected session/client-ID persistence,
and response normalization for either native PocketBase auth responses or a
trusted backend proxy. It does not expose superuser credentials or require
games to connect directly to PocketBase.

## Installation

```sh
gdam install @aviorstudio/gd-pocketbase
```

## Quick start

```gdscript
const AuthResponseModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/auth_response_module.gd"
)
const SessionStoreModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/session_store_module.gd"
)
const CredentialAdapter = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/credential_adapter.gd"
)

# Implement this boundary with the target OS credential facility. Its writes
# must be atomic; never bundle an encryption key in the game.
class NativeCredentials extends CredentialAdapter:
	func read_value(key: String) -> Result:
		return Result.new(Status.UNAVAILABLE, "", "connect the platform credential API")
	func write_value(key: String, value: String) -> Result:
		return Result.new(Status.UNAVAILABLE, "", "connect the platform credential API")

var auth := AuthResponseModule.normalize(response_json)
var config := SessionStoreModule.SessionStoreConfig.new()
config.native_adapter = NativeCredentials.new()
var store := SessionStoreModule.new(config)
var saved := store.save(auth)
if not saved.is_ok():
	push_error(saved.detail)
```

`AuthResponseModule.normalize()` accepts native PocketBase
`{"token", "record"}` responses and backend-proxy
`{"access_token", "user"}` responses.

## Modules

- `AuthResponseModule`: normalize auth responses without coupling UI code to a
  transport.
- `JwtModule`: decode at most a 16 KiB JWT / 8 KiB payload and return typed
  `VALID`, `EXPIRED`, or `INVALID` expiry metadata. `exp` is required, finite,
  positive, and integral. Default skew is zero; callers may pass a nonnegative
  skew. Every decoded field is explicitly untrusted: this module does not
  verify signatures, authorize, or establish identity.
- `SessionStoreModule`: store at most 64 KiB of acyclic JSON-compatible data
  (depth 16). Native callers must inject an atomic OS-credential adapter; no
  plaintext or bundled-key fallback exists. Web uses process memory only, so
  values do not survive reload. Migration occurs only after destination
  write/readback succeeds, and legacy source files are retained. Logout writes
  a verified tombstone so retained legacy data cannot be remigrated.
- `ClientIdModule`: generate a random ID through the same persistence policy.
  Keys—including quotes and newlines—remain data and are never interpolated
  into JavaScript. Web randomness uses the JavaScript object API, not `eval`.

Games own HTTP transport, refresh/revoke policy, and server trust. A production
backend should keep PocketBase superuser credentials private.

### Approved policy decisions

- **D-06:** PocketBase and Supabase remain independent provider adapters with
  identical external contracts; no new shared repository was introduced.
- **D-07:** native persistence requires an injected OS-credential adapter;
  web persistence is memory-only. Browser memory is script-accessible and is
  not a secure keystore. No bundled-key security claim is made.
- **D-08:** legacy data is never deleted by migration. A destination is usable
  only after a successful commit/readback.

> **Correction ([fieldsofrevik#149](https://github.com/aviorstudio/fieldsofrevik/issues/149)):**
> The earlier README described JWT decoding as an expiry check without stating
> that missing/malformed `exp` was treated as active, and described persistence
> and stable IDs without disclosing plaintext files or browser `localStorage`.
> The APIs above replace those unsafe/ambiguous contracts; there is no
> compatibility shim.

## Testing

```sh
./tests/test.sh
```

> **Correction ([fieldsofrevik#149](https://github.com/aviorstudio/fieldsofrevik/issues/149)):**
> Earlier CI and release text overstated what a green run proved. The prior
> runner could accept engine errors followed by a zero exit and did not test the
> packaged ZIP or editor lifecycle. Current gates require error-log rejection,
> reachable assertion sentinels, bounded execution, a closed package manifest,
> and enable/restart/smoke/disable/restart checks against the assembled ZIP.

## License

MIT
