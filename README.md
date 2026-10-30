<!-- Generated from private documentation source. Do not edit directly. Source SHA256: 946e8fe387839d69ec9b31f1de6407dfcd34d83bf203eb051f6d4784de02fadb -->

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
