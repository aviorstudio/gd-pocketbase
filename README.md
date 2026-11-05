<!-- Generated from private documentation source. Do not edit directly. Source SHA256: d1ae933e32b853c041e3e6d0d4060591a6c99186ebc8d8a02acd3b5467ce113f -->

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
make setup
make build
make test
```

`make help` lists the available commands. `mise.toml` pins SDK versions; `cookbook.toml` declares package inputs and native tests. Shared automation comes from the exact `nicodes/tools` revision in `Makefile`. Engine and template downloads are checksum verified.

`make build` packages the addon, validates its closed file manifest and checksums, and prepares any declared native export fixtures. `make test` runs all declared source, security and behavioral groups against the current source and prebuilt package. Individual groups are available as `make test:lint`, `make test:unit`, `make test:security`, and the integration or browser groups listed by `make help`. Tests do not prepare dependencies or rebuild the addon. Build and test receipts stay in `.artifacts/verification`.

`make fmt` formats owned GDScript. `make clean` removes declared generated outputs while preserving source and retained data. This package has no application development service.
