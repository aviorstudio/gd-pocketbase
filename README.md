<!-- Generated from private documentation source. Do not edit directly. Source SHA256: bfa36199be62bf4e7a62c9df006fee0b4c4a228e757a54492c899ef30cdad416 -->

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

## Repository development

Install the [Komizo release](https://github.com/nicodes/komizo#install) matching `komizo.lock`.

```sh
komizo check                 # Source, runtime, package and installed-addon checks
komizo run test              # Focused addon test suite
komizo run artifact-check    # Verify the built package
```

The addon recipe supplies the verified Godot engine and templates in checkout-owned tool/data directories. Interactive use belongs to a consuming Godot project.
