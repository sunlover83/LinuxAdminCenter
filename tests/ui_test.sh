#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

passed=0
failed=0

pass_test() {
    printf '[PASS] %s\n' "$1"
    passed=$((passed + 1))
}

fail_test() {
    printf '[FAIL] %s\n' "$1"
    failed=$((failed + 1))
}

assert_output_contains() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Actual:   %s\n' "$actual"
    fi
}

assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Actual:   %s\n' "$actual"
    fi
}

# shellcheck source=../src/core/ui.sh
source "${PROJECT_ROOT}/src/core/ui.sh"

show_hardware_diagnostics() {
    printf '%s\n' "hardware diagnostics selected"
}

printf '%s\n\n' "Running UI tests..."

assert_output_contains \
    "Main menu displays hardware diagnostics" \
    "5) Hardware Diagnostics" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu still displays system cleanup" \
    "4) System Cleanup" \
    "$(draw_main_menu)"

assert_equals \
    "Menu option 5 starts hardware diagnostics" \
    "hardware diagnostics selected" \
    "$(read_choice <<< "5")"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
