#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ZIP_PATH=${1:-"$ROOT_DIR/dist/@aviorstudio_gd-pocketbase.zip"}
GODOT=${GODOT_BIN:-godot}
FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT
ADDON_DIR="$FIXTURE/addons/@aviorstudio_gd-pocketbase"
mkdir -p "$ADDON_DIR"
unzip -q "$ZIP_PATH" -d "$ADDON_DIR"

cat >"$FIXTURE/project.godot" <<'EOF'
[application]
config/name="GD PocketBase packaged lifecycle"

[rendering]
renderer/rendering_method="gl_compatibility"
EOF

run_editor() {
    timeout --signal=TERM --kill-after=2 30s "$GODOT" --headless --editor \
        --path "$FIXTURE" --quit >/dev/null 2>&1
}

# Clean editor, enable, restart while enabled.
run_editor
cat >>"$FIXTURE/project.godot" <<'EOF'

[editor_plugins]
enabled=PackedStringArray("res://addons/@aviorstudio_gd-pocketbase/plugin.cfg")
EOF
run_editor
run_editor

cp "$ROOT_DIR/tests/packaged_smoke.gd" "$FIXTURE/packaged_smoke.gd"
python3 "${TOOLS_ROOT:?Run make setup}/helpers/godot-test.py" \
    --project "$FIXTURE" --program "$FIXTURE/packaged_smoke.gd" --timeout 30 \
    --sentinel-regex '^TEST_SENTINEL:packaged_smoke\.gd:([1-9][0-9]*)$'

# Disable and restart twice. The addon owns no autoload or consumer setting.
python3 - "$FIXTURE/project.godot" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.split("\n[editor_plugins]\n", 1)[0].rstrip() + "\n"
path.write_text(text)
PY
run_editor
run_editor

if grep -Eq '^\[autoload\]|@aviorstudio_gd-pocketbase' "$FIXTURE/project.godot"; then
    echo "Addon lifecycle left owned project configuration" >&2
    exit 1
fi

python3 "${TOOLS_ROOT:?Run make setup}/helpers/addon-package.py" verify \
    --archive "$ZIP_PATH" --manifest "$ROOT_DIR/package.files" \
    --source "$ROOT_DIR/addon" --installed "$ADDON_DIR" --script-uids

TREE_SHA=$(cd "$ADDON_DIR" && find . -type f -print0 | sort -z | \
    xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
echo "INSTALLED_TREE_SHA256:$TREE_SHA"
echo "PACKAGED_LIFECYCLE_PASS:enable-restart-smoke-disable-restart"
