#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT
export XDG_CONFIG_HOME="$TEST_HOME/config"
export XDG_DATA_HOME="$TEST_HOME/data"

"$SCRIPT_DIR/gate_self_test.sh"

mapfile -t TESTS < <(printf '%s\n' "$SCRIPT_DIR"/*_test.gd | sort)
if [[ ${#TESTS[@]} -eq 0 || ! -f "${TESTS[0]}" ]]; then
    echo "No GDScript tests found" >&2
    exit 1
fi

for test in "${TESTS[@]}"; do
    name=$(basename "$test")
    escaped=${name//./\\.}
    python3 "${TOOLS_ROOT:?Run make setup}/helpers/godot-test.py" \
        --project "$ROOT_DIR" --program "$test" --timeout 30 \
        --sentinel-regex "^TEST_SENTINEL:${escaped}:([1-9][0-9]*)$"
done

echo "TEST_SUITE_PASS:gdscripts:${#TESTS[@]}"
