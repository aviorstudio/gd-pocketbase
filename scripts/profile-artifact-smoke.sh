#!/usr/bin/env bash
set -euo pipefail
mkdir -p dist/web
"${GODOT_BIN:-godot}" --headless --path . --export-release Web dist/web/index.html
bash scripts/verify_installed_package.sh
