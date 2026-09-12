# gd-pocketbase

PocketBase-friendly auth and session primitives for Godot 4.

The addon provides JWT expiry checks, persisted sessions, stable client IDs,
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

var auth := AuthResponseModule.normalize(response_json)
var store := SessionStoreModule.new()
store.save(auth)
```

`AuthResponseModule.normalize()` accepts native PocketBase
`{"token", "record"}` responses and backend-proxy
`{"access_token", "user"}` responses.

## Modules

- `AuthResponseModule`: normalize auth responses without coupling UI code to a
  transport.
- `JwtModule`: decode JWT claims and check expiry. It does not verify
  signatures.
- `SessionStoreModule`: save, load, migrate, and clear local session files.
- `ClientIdModule`: provide a stable native or browser client ID.

Games own HTTP transport, refresh/revoke policy, and server trust. A production
backend should keep PocketBase superuser credentials private.

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
