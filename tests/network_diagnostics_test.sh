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

# shellcheck source=../src/modules/network_diagnostics/network_diagnostics.sh
source "${PROJECT_ROOT}/src/modules/network_diagnostics/network_diagnostics.sh"

get_network_diagnostic_tool_status() {
    case "$1" in
        ip|ping|getent)
            printf '%s\n' "available"
            ;;
        *)
            printf '%s\n' "not installed"
            ;;
    esac
}

get_default_gateway_address() {
    printf '%s\n' "192.168.1.1"
}

get_gateway_connectivity() {
    printf '%s\n' \
        "reachable|packet_loss=0%|average_latency=1.2 ms"
}

get_dns_resolution_status() {
    printf '%s\n' "working"
}

get_internet_connectivity() {
    printf '%s\n' \
        "reachable|packet_loss=0%|average_latency=12.5 ms"
}

printf '%s\n\n' "Running network diagnostics tests..."

assert_equals \
    "Reachable ping results are formatted" \
    "reachable | packet loss: 0% | average latency: 12.5 ms" \
    "$(
        format_ping_diagnostics \
            "reachable|packet_loss=0%|average_latency=12.5 ms"
    )"

assert_equals \
    "Unreachable ping results are formatted" \
    "unreachable | packet loss: 100% | average latency: unknown" \
    "$(
        format_ping_diagnostics \
            "unreachable|packet_loss=100%|average_latency=unknown"
    )"

assert_equals \
    "Simple diagnostic states remain unchanged" \
    "unavailable" \
    "$(format_ping_diagnostics unavailable)"

assert_equals \
    "Ping connectivity status is extracted" \
    "reachable" \
    "$(
        get_ping_connectivity_status \
            "reachable|packet_loss=0%|average_latency=1.2 ms"
    )"

assert_equals \
    "Successful checks produce a healthy summary" \
    "healthy" \
    "$(
        get_network_diagnostic_summary \
            "192.168.1.1" \
            "reachable|packet_loss=0%|average_latency=1.2 ms" \
            "working" \
            "reachable|packet_loss=0%|average_latency=12.5 ms"
    )"

assert_equals \
    "A blocked gateway ping produces a warning" \
    "warning" \
    "$(
        get_network_diagnostic_summary \
            "192.168.1.1" \
            "unreachable|packet_loss=100%|average_latency=unknown" \
            "working" \
            "reachable|packet_loss=0%|average_latency=12.5 ms"
    )"

assert_equals \
    "A blocked external ping produces a warning" \
    "warning" \
    "$(
        get_network_diagnostic_summary \
            "192.168.1.1" \
            "reachable|packet_loss=0%|average_latency=1.2 ms" \
            "working" \
            "unreachable|packet_loss=100%|average_latency=unknown"
    )"

assert_equals \
    "DNS failure with working IP connectivity produces a warning" \
    "warning" \
    "$(
        get_network_diagnostic_summary \
            "192.168.1.1" \
            "reachable|packet_loss=0%|average_latency=1.2 ms" \
            "failed" \
            "reachable|packet_loss=0%|average_latency=12.5 ms"
    )"

assert_equals \
    "A missing default gateway produces a failed summary" \
    "failed" \
    "$(
        get_network_diagnostic_summary \
            "none" \
            "no gateway" \
            "failed" \
            "unreachable|packet_loss=100%|average_latency=unknown"
    )"

assert_equals \
    "Failed DNS and external reachability produce a failed summary" \
    "failed" \
    "$(
        get_network_diagnostic_summary \
            "192.168.1.1" \
            "unreachable|packet_loss=100%|average_latency=unknown" \
            "failed" \
            "unreachable|packet_loss=100%|average_latency=unknown"
    )"

assert_equals \
    "Blocked external ICMP receives an explanatory message" \
    "DNS resolution works, but the external ping target did not respond; ICMP may be blocked." \
    "$(
        get_network_diagnostic_summary_message \
            "192.168.1.1" \
            "reachable|packet_loss=0%|average_latency=1.2 ms" \
            "working" \
            "unreachable|packet_loss=100%|average_latency=unknown"
    )"

diagnostics_output="$(print_network_diagnostics)"

assert_output_contains \
    "Network diagnostics display tool availability" \
    "ping:          available" \
    "$diagnostics_output"

assert_output_contains \
    "Network diagnostics display the default gateway" \
    "Default gateway:  192.168.1.1" \
    "$diagnostics_output"

assert_output_contains \
    "Network diagnostics display gateway connectivity" \
    "Gateway test:     reachable | packet loss: 0%" \
    "$diagnostics_output"

assert_output_contains \
    "Network diagnostics display DNS resolution" \
    "DNS resolution:   working (example.com)" \
    "$diagnostics_output"

assert_output_contains \
    "Network diagnostics display internet connectivity" \
    "Internet test:    reachable | packet loss: 0%" \
    "$diagnostics_output"

assert_output_contains \
    "Network diagnostics display the internet target" \
    "Internet target:  1.1.1.1" \
    "$diagnostics_output"

assert_output_contains \
    "Network diagnostics display the overall status" \
    "Status:   healthy" \
    "$diagnostics_output"

assert_output_contains \
    "Network diagnostics display assessment details" \
    "Details:  All connectivity checks passed." \
    "$diagnostics_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
