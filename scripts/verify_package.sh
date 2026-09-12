#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ZIP_PATH=${1:-"$ROOT_DIR/dist/@aviorstudio_gd-pocketbase.zip"}
EXPECTED="$ROOT_DIR/scripts/package_manifest.txt"
ACTUAL=$(mktemp)
trap 'rm -f "$ACTUAL"' EXIT

test -f "$ZIP_PATH"
unzip -Z1 "$ZIP_PATH" | LC_ALL=C sort >"$ACTUAL"
diff -u "$EXPECTED" "$ACTUAL"

if unzip -Z1 "$ZIP_PATH" | grep -Eq '(^/|(^|/)\.\.(/|$)|\\)'; then
    echo "Archive contains an unsafe path" >&2
    exit 1
fi
if zipinfo -l "$ZIP_PATH" | grep -Eq '^l'; then
    echo "Archive contains a symlink" >&2
    exit 1
fi

echo "PACKAGE_MANIFEST_PASS:$(wc -l < "$ACTUAL")"
