#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

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

# shellcheck source=../src/modules/self_check/self_check.sh
source "${PROJECT_ROOT}/src/modules/self_check/self_check.sh"

printf '%s\n\n' "Running self-check tests..."

assert_equals \
    "Complete LAC environments are healthy" \
    "healthy" \
    "$(get_lac_self_check_status \
        "compatible (5.2)" \
        "complete" \
        "available" \
        "complete" \
        "defaults" \
        "defaults" \
        "apt|available")"

assert_equals \
    "Unsupported Bash versions fail the self-check" \
    "failed" \
    "$(get_lac_self_check_status \
        "unsupported (4.2)" \
        "complete" \
        "available" \
        "complete" \
        "defaults" \
        "defaults" \
        "apt|available")"

assert_equals \
    "Missing runtime files fail the self-check" \
    "failed" \
    "$(get_lac_self_check_status \
        "compatible (5.2)" \
        "missing (1)" \
        "available" \
        "complete" \
        "defaults" \
        "defaults" \
        "apt|available")"

assert_equals \
    "Incomplete system launchers fail the self-check" \
    "failed" \
    "$(get_lac_self_check_status \
        "compatible (5.2)" \
        "complete" \
        "incomplete" \
        "complete" \
        "defaults" \
        "defaults" \
        "apt|available")"

assert_equals \
    "Missing core tools warn in the self-check" \
    "warning" \
    "$(get_lac_self_check_status \
        "compatible (5.2)" \
        "complete" \
        "available" \
        "missing (1)" \
        "defaults" \
        "defaults" \
        "apt|available")"

assert_equals \
    "Unreadable configuration warns in the self-check" \
    "warning" \
    "$(get_lac_self_check_status \
        "compatible (5.2)" \
        "complete" \
        "available" \
        "complete" \
        "not readable" \
        "defaults" \
        "apt|available")"

assert_equals \
    "Unavailable package managers warn in the self-check" \
    "warning" \
    "$(get_lac_self_check_status \
        "compatible (5.2)" \
        "complete" \
        "available" \
        "complete" \
        "defaults" \
        "defaults" \
        "unknown|unavailable")"

assert_output_contains \
    "Healthy self-checks receive an explanatory message" \
    "runtime, launchers, configuration handling and required core tools are ready" \
    "$(get_lac_self_check_message \
        "healthy" \
        "compatible (5.2)" \
        "complete" \
        "available" \
        "complete" \
        "defaults" \
        "defaults" \
        "apt|available")"

assert_output_contains \
    "Unsupported Bash receives a specific explanation" \
    "older than the supported minimum of 4.3" \
    "$(get_lac_self_check_message \
        "failed" \
        "unsupported (4.2)" \
        "complete" \
        "available" \
        "complete" \
        "defaults" \
        "defaults" \
        "apt|available")"

LAC_VERSION="test-version"
LAC_CODENAME="Test"

get_lac_runtime_root() { printf '%s\n' "/usr/local/lib/linux-admin-center"; }
get_lac_installation_type() { printf '%s\n' "system-wide"; }
get_bash_runtime_status() { printf '%s\n' "compatible (5.2.0)"; }
get_lac_runtime_files_status() { printf '%s\n' "complete"; }
get_lac_launcher_status() { printf '%s\n' "available"; }
get_lac_system_config_status() { printf '%s\n' "defaults"; }
get_lac_user_config_status() { printf '%s\n' "available"; }
get_lac_required_tools_status() { printf '%s\n' "complete"; }
get_lac_required_tool_records() {
    printf '%s\n' "awk|available" "sed|available"
}
get_lac_optional_tool_records() {
    printf '%s\n' "vulkaninfo|available" "gamescope|not installed"
}
get_lac_package_manager_status() { printf '%s\n' "apt|available"; }

formatted_output="$(print_lac_self_check)"

assert_output_contains \
    "Self-check output displays the installation type" \
    "Installation:           system-wide" \
    "$formatted_output"

assert_output_contains \
    "Self-check output displays runtime file status" \
    "Runtime files:          complete" \
    "$formatted_output"

assert_output_contains \
    "Self-check output displays system configuration status" \
    "System configuration:   defaults" \
    "$formatted_output"

assert_output_contains \
    "Self-check output displays required tools" \
    "awk:                    available" \
    "$formatted_output"

assert_output_contains \
    "Self-check output displays optional tools without requiring them" \
    "gamescope:              not installed" \
    "$formatted_output"

assert_output_contains \
    "Self-check output displays a healthy overall status" \
    "Status:                 healthy" \
    "$formatted_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
