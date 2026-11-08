#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
FIXTURES="$SCRIPT_DIR/fixtures/gate"

run_case() {
    local program=$1
    local name
    name=$(basename "$program")
    local escaped=${name//./\\.}
    python3 "${TOOLS_ROOT:?Run mise run setup}/helpers/godot-test.py" \
        --project "$ROOT_DIR" --program "$program" --timeout "${TEST_TIMEOUT_SECONDS:-30}" \
        --sentinel-regex "^TEST_SENTINEL:${escaped}:([1-9][0-9]*)$"
}

expect_pass() {
    local name=$1
    TEST_TIMEOUT_SECONDS=5 run_case "$FIXTURES/$name" >/dev/null
    echo "GATE_CONTROL_RESTORED:$name:pass"
}

expect_fail() {
    local name=$1
    local timeout_seconds=${2:-5}
    if TEST_TIMEOUT_SECONDS="$timeout_seconds" run_case "$FIXTURES/$name" >/dev/null 2>&1; then
        echo "Negative gate control unexpectedly passed: $name" >&2
        exit 1
    fi
    echo "GATE_CONTROL_REJECTED:$name"
}

expect_pass success.gd
expect_fail push_error_zero_exit.gd
expect_fail overwritten_quit.gd
expect_fail parse_failure.gd
expect_fail timeout.gd 1
expect_fail unreachable_assertion.gd
expect_fail unexpected_log_error.gd
expect_fail missing_test.gd

echo "GATE_SELF_TEST_PASS:8"
