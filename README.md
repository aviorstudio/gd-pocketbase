<!-- Generated from private documentation source. Do not edit directly. Source SHA256: 4ca03bd438de45d6871390f3dd765aeb082bc43dd5669f4798042c68bf54c29a -->

# gd-pocketbase

Normalises PocketBase auth responses for Godot 4.

`AuthResponseModule.normalize()` turns either a native PocketBase
`{"token", "record"}` response or a trusted backend-proxy
`{"access_token", "user"}` response into one shape:
`{"access_token", "user": {"id", "email", "username"}}`. That is the whole
addon. The session store, client ID and JWT helpers it used to carry were a
copy of a backend-neutral core that now lives in
[`@aviorstudio/gd-session`](https://github.com/aviorstudio/gd-session);
install that beside this addon to persist what `normalize()` returns.

## Installation

```sh
gdam add @aviorstudio/gd-pocketbase
gdam add @aviorstudio/gd-session
```

## Quick start

```gdscript
const AuthResponseModule = preload(
	"res://addons/@aviorstudio_gd-pocketbase/src/auth_response_module.gd"
)
const SessionStoreModule = preload(
	"res://addons/@aviorstudio_gd-session/src/session_store_module.gd"
)

var auth := AuthResponseModule.normalize(response_json)
var config := SessionStoreModule.SessionStoreConfig.new()
config.native_adapter = NativeCredentials.new()  # see gd-session's README
var saved := SessionStoreModule.new(config).save(auth)
if not saved.is_ok():
	push_error(saved.detail)
```

Games own HTTP transport, refresh and revoke policy, and server trust. A
production backend should keep PocketBase superuser credentials private; this
addon never needs them.

## License

See `LICENSE`.

## Contributor checks

Install [mise](https://mise.jdx.dev/), then prepare the pinned cookbook and SDKs:

```sh
mise run setup
mise run build
mise run test
```

`mise run help` lists the available commands. `mise.toml` pins SDK versions; `cookbook.toml` declares package inputs and native tests. Shared recipes come from the exact `nicodes/cookbook` revision in the generated `mise.toml` task block. Engine and template downloads are checksum verified.

`mise run build` packages the addon, validates its closed file manifest and checksums, and prepares any declared native export fixtures. `mise run test` runs all declared source, security and behavioral groups against the current source and prebuilt package. Individual groups are available as `mise run test:lint`, `mise run test:unit`, `mise run test:security`, and the integration or browser groups listed by `mise run help`. Tests do not prepare dependencies or rebuild the addon. Build and test receipts stay in `.artifacts/verification`.

`mise run fmt` formats owned GDScript. `mise run clean` removes declared generated outputs while preserving source and retained data. This package has no application development service.
