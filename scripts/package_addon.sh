#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT=${1:-"$ROOT_DIR/dist/@aviorstudio_gd-pocketbase.zip"}
mkdir -p "$(dirname "$OUTPUT")"
rm -f "$OUTPUT"

if git -C "$ROOT_DIR" ls-files --stage addon | grep -q '^120000 '; then
    echo "Addon package rejects symlinks" >&2
    exit 1
fi

git -C "$ROOT_DIR" archive --format=zip --output="$OUTPUT" HEAD:addon
(
    cd "$(dirname "$OUTPUT")"
    sha256sum "$(basename "$OUTPUT")" >"$(basename "$OUTPUT").sha256"
)
echo "PACKAGE_ZIP_SHA256:$(sha256sum "$OUTPUT" | cut -d' ' -f1)"
