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

# shellcheck source=../src/modules/service_health/service_health.sh
source "${PROJECT_ROOT}/src/modules/service_health/service_health.sh"

get_init_system() {
    printf '%s\n' "systemd"
}

get_service_tool_status() {
    printf '%s\n' "available"
}

get_systemd_system_state() {
    printf '%s\n' "degraded"
}

get_systemd_service_counts() {
    printf '%s\n' "active=42|inactive=8|failed=2"
}

get_failed_systemd_service_count() {
    printf '%s\n' "2"
}

get_failed_systemd_services() {
    printf '%s\n' \
        "example.service" \
        "backup.service"
}

get_systemd_failed_service_details() {
    case "$1" in
        example.service)
            printf '%s\n' \
                "unit=example.service|description=Example background service|load=loaded|active=failed|sub=failed"
            ;;
        backup.service)
            printf '%s\n' \
                "unit=backup.service|description=Backup service|load=loaded|active=failed|sub=exit-code"
            ;;
        *)
            printf '%s\n' "unknown"
            ;;
    esac
}

get_systemd_boot_time() {
    printf '%s\n' "30.698s"
}

get_slowest_systemd_services() {
    printf '%s\n' \
        "NetworkManager-wait-online.service|5.432s" \
        "docker.service|1.250s" \
        "cups.service|800ms"
}

printf '%s\n\n' "Running service health tests..."

assert_equals \
    "Running systemd without failed services is healthy" \
    "healthy" \
    "$(get_service_health_summary systemd running 0)"

assert_equals \
    "A failed service produces a warning" \
    "warning" \
    "$(get_service_health_summary systemd running 1)"

assert_equals \
    "A degraded systemd state produces a warning" \
    "warning" \
    "$(get_service_health_summary systemd degraded 0)"

assert_equals \
    "Systemd maintenance mode produces a failed status" \
    "failed" \
    "$(get_service_health_summary systemd maintenance 0)"

assert_equals \
    "Unknown systemd states produce a failed status" \
    "failed" \
    "$(get_service_health_summary systemd unknown 0)"

assert_equals \
    "Unsupported init systems produce a failed status" \
    "failed" \
    "$(get_service_health_summary openrc unsupported unsupported)"

assert_equals \
    "Unavailable service counts produce a failed status" \
    "failed" \
    "$(get_service_health_summary systemd running unavailable)"

assert_equals \
    "Healthy systems receive a successful explanation" \
    "Systemd is running and no failed services were detected." \
    "$(
        get_service_health_summary_message \
            systemd \
            running \
            0
    )"

assert_equals \
    "One failed service receives a singular explanation" \
    "One failed systemd service was detected." \
    "$(
        get_service_health_summary_message \
            systemd \
            degraded \
            1
    )"

assert_equals \
    "Multiple failed services receive a plural explanation" \
    "2 failed systemd services were detected." \
    "$(
        get_service_health_summary_message \
            systemd \
            degraded \
            2
    )"

assert_equals \
    "Unsupported init systems receive an explanation" \
    "Service Health currently supports systemd systems only." \
    "$(
        get_service_health_summary_message \
            openrc \
            unsupported \
            unsupported
    )"

assert_equals \
    "Maintenance mode receives an explanation" \
    "Systemd is in maintenance mode." \
    "$(
        get_service_health_summary_message \
            systemd \
            maintenance \
            0
    )"

assert_equals \
    "Service count fields are parsed" \
    "42" \
    "$(
        get_service_record_value \
            "active=42|inactive=8|failed=2" \
            active
    )"

assert_equals \
    "Unavailable records preserve their state" \
    "unavailable" \
    "$(get_service_record_value unavailable active)"

assert_equals \
    "Service descriptions are parsed" \
    "Example background service" \
    "$(
        get_service_record_value \
            "unit=example.service|description=Example background service|load=loaded|active=failed|sub=failed" \
            description
    )"

service_output="$(print_service_health)"

assert_output_contains \
    "Service Health displays the init system" \
    "Init system:             systemd" \
    "$service_output"

assert_output_contains \
    "Service Health displays systemctl availability" \
    "systemctl:               available" \
    "$service_output"

assert_output_contains \
    "Service Health displays the system state" \
    "System state:            degraded" \
    "$service_output"

assert_output_contains \
    "Service Health displays active service counts" \
    "Active services:         42" \
    "$service_output"

assert_output_contains \
    "Service Health displays inactive service counts" \
    "Inactive services:       8" \
    "$service_output"

assert_output_contains \
    "Service Health displays failed service counts" \
    "Failed services:         2" \
    "$service_output"

assert_output_contains \
    "Service Health displays failed service names" \
    "example.service" \
    "$service_output"

assert_output_contains \
    "Service Health displays failed service descriptions" \
    "Description:           Example background service" \
    "$service_output"

assert_output_contains \
    "Service Health displays the total boot time" \
    "Total boot time:         30.698s" \
    "$service_output"

assert_output_contains \
    "Service Health displays slow services" \
    "NetworkManager-wait-online.service" \
    "$service_output"

assert_output_contains \
    "Service Health displays warning assessments" \
    "Status:                  warning" \
    "$service_output"

assert_output_contains \
    "Service Health displays assessment details" \
    "Details:                 2 failed systemd services were detected." \
    "$service_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
