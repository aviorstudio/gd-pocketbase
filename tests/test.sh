#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
GODOT="${GODOT_BIN:-godot}"
TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT
export XDG_CONFIG_HOME="$TEST_HOME/config"
export XDG_DATA_HOME="$TEST_HOME/data"
FAILURES=0
for test in "$SCRIPT_DIR"/*_test.gd; do
    echo "Running $(basename "$test")..."
    if ! "$GODOT" --headless --path "$ROOT_DIR" --script "$test" 2>&1; then
        FAILURES=$((FAILURES + 1))
    fi
done
exit $FAILURES
