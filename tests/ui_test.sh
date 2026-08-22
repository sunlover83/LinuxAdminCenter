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

show_network_diagnostics() {
    printf '%s\n' "network diagnostics selected"
}

show_gaming_readiness() {
    printf '%s\n' "gaming readiness selected"
}

show_service_health() {
    printf '%s\n' "service health selected"
}

show_gaming_diagnostics() {
    printf '%s\n' "gaming diagnostics selected"
}

show_lac_self_check() {
    printf '%s\n' "self check selected"
}

show_storage_analysis() {
    printf '%s\n' "storage analysis selected"
}

printf '%s\n\n' "Running UI tests..."

assert_output_contains \
    "Main menu displays hardware diagnostics" \
    "5) Hardware Diagnostics" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu displays network diagnostics" \
    "6) Network Diagnostics" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu displays gaming readiness" \
    "7) Gaming Readiness" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu displays service health" \
    "8) Service Health" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu displays gaming diagnostics" \
    "9) Gaming Diagnostics" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu displays LAC self check" \
    "10) LAC Self Check" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu displays storage analysis" \
    "11) Storage Analysis" \
    "$(draw_main_menu)"

assert_output_contains \
    "Main menu still displays system cleanup" \
    "4) System Cleanup" \
    "$(draw_main_menu)"

assert_equals \
    "Menu option 5 starts hardware diagnostics" \
    "hardware diagnostics selected" \
    "$(read_choice <<< "5")"

assert_equals \
    "Menu option 6 starts network diagnostics" \
    "network diagnostics selected" \
    "$(read_choice <<< "6")"

assert_equals \
    "Menu option 7 starts gaming readiness" \
    "gaming readiness selected" \
    "$(read_choice <<< "7")"

assert_equals \
    "Menu option 8 starts service health" \
    "service health selected" \
    "$(read_choice <<< "8")"

assert_equals \
    "Menu option 9 starts gaming diagnostics" \
    "gaming diagnostics selected" \
    "$(read_choice <<< "9")"

assert_equals \
    "Menu option 10 starts LAC self check" \
    "self check selected" \
    "$(read_choice <<< "10")"

assert_equals \
    "Menu option 11 starts storage analysis" \
    "storage analysis selected" \
    "$(read_choice <<< "11")"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
