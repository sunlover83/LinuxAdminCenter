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

printf '%s\n\n' "Running system information tests..."

assert_output_contains \
    "System information includes the hostname" \
    "Hostname:" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes the kernel version" \
    "Kernel:" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes the architecture" \
    "Architecture:" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes the uptime" \
    "Uptime:" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes memory usage" \
    "Memory:" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes root disk usage" \
    "Root disk:" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes load averages" \
    "Load average:" \
    "$LAC_SCRIPT" \
    --system-info

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
