#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 PROJECT_DIR TEST_SCRIPT" >&2
    exit 2
fi

PROJECT_DIR=$1
TEST_SCRIPT=$2
GODOT=${GODOT_BIN:-godot}
TIMEOUT_SECONDS=${TEST_TIMEOUT_SECONDS:-30}
SCRIPT_NAME=$(basename "$TEST_SCRIPT")
LOG_FILE=$(mktemp)
trap 'rm -f "$LOG_FILE"' EXIT

if [[ ! -f "$TEST_SCRIPT" ]]; then
    echo "Missing GDScript test: $TEST_SCRIPT" >&2
    exit 1
fi

echo "Running $SCRIPT_NAME..."
set +e
timeout --signal=TERM --kill-after=2 "${TIMEOUT_SECONDS}s" \
    "$GODOT" --headless --path "$PROJECT_DIR" --script "$TEST_SCRIPT" \
    >"$LOG_FILE" 2>&1
STATUS=$?
set -e
cat "$LOG_FILE"

if [[ $STATUS -eq 124 || $STATUS -eq 137 ]]; then
    echo "Timed out after ${TIMEOUT_SECONDS}s: $SCRIPT_NAME" >&2
    exit 1
fi
if [[ $STATUS -ne 0 ]]; then
    echo "Godot exited $STATUS: $SCRIPT_NAME" >&2
    exit 1
fi

if grep -Eq '(^|[[:space:]])(SCRIPT ERROR|ERROR):' "$LOG_FILE"; then
    echo "Unexpected Godot error output: $SCRIPT_NAME" >&2
    exit 1
fi

SENTINEL="TEST_SENTINEL:${SCRIPT_NAME}:"
if ! grep -Eq "^${SENTINEL}[1-9][0-9]*$" "$LOG_FILE"; then
    echo "Missing reachable assertion sentinel: $SCRIPT_NAME" >&2
    exit 1
fi
