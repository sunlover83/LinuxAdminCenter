#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAC_SCRIPT="${PROJECT_ROOT}/src/lac.sh"

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
    local output
    local status

    shift 2

    if output=$("$@" 2>&1); then
        status=0
    else
        status=$?
    fi

    if (( status == 0 )) && [[ "$output" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Output:   %s\n' "$output"
        printf '       Status:   %s\n' "$status"
    fi
}

assert_failure_contains() {
    local description="$1"
    local expected_status="$2"
    local expected_output="$3"
    local output
    local actual_status

    shift 3

    if output=$("$@" 2>&1); then
        actual_status=0
    else
        actual_status=$?
    fi

    if (( actual_status == expected_status )) &&
        [[ "$output" == *"$expected_output"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected status: %s\n' "$expected_status"
        printf '       Actual status:   %s\n' "$actual_status"
        printf '       Expected output: %s\n' "$expected_output"
        printf '       Output:          %s\n' "$output"
    fi
}

printf '%s\n\n' "Running CLI tests..."

assert_output_contains \
    "Long version option displays the LAC version" \
    "Linux Admin Center 0.1.0-alpha (Foundation)" \
    "$LAC_SCRIPT" \
    --version

assert_output_contains \
    "Short version option displays the LAC version" \
    "Linux Admin Center 0.1.0-alpha (Foundation)" \
    "$LAC_SCRIPT" \
    -v

assert_output_contains \
    "Long system information option displays package manager" \
    "Package manager:" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "Short system information option displays restart status" \
    "Restart required:" \
    "$LAC_SCRIPT" \
    -i

assert_output_contains \
    "Long help option displays usage information" \
    "Usage:" \
    "$LAC_SCRIPT" \
    --help

assert_output_contains \
    "Short help option displays usage information" \
    "Options:" \
    "$LAC_SCRIPT" \
    -h

assert_failure_contains \
    "Unknown options return status 2" \
    2 \
    "Error: Unknown option: --unknown" \
    "$LAC_SCRIPT" \
    --unknown

assert_failure_contains \
    "Multiple options return status 2" \
    2 \
    "Error: Exactly one option is expected." \
    "$LAC_SCRIPT" \
    --help \
    --version

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
