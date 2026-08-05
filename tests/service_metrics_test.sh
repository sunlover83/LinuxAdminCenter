#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"
TEST_PROC_ROOT="${TEST_TMP_DIR}/proc"

mkdir -p \
    "$MOCK_BIN" \
    "${TEST_PROC_ROOT}/1"

trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${PATH}"
export LAC_PROC_ROOT="$TEST_PROC_ROOT"

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

cat > "${MOCK_BIN}/ps" <<'EOF_PS'
#!/usr/bin/env bash

if [[ "$*" == "-p 1 -o comm=" ]]; then
    printf '%s\n' "systemd"
    exit 0
fi

exit 1
EOF_PS

chmod +x "${MOCK_BIN}/ps"

cat > "${MOCK_BIN}/systemctl" <<'EOF_SYSTEMCTL'
#!/usr/bin/env bash

case "$*" in
    "is-system-running")
        printf '%s\n' "degraded"
        exit 1
        ;;
    "list-units --type=service --state=failed --no-legend --no-pager --plain")
        cat <<'OUTPUT'
example.service loaded failed failed Example background service
● backup.service loaded failed failed Backup service
OUTPUT
        ;;
    "list-units --type=service --all --no-legend --no-pager --plain")
        cat <<'OUTPUT'
ssh.service loaded active running OpenSSH server
cups.service loaded inactive dead Printing service
backup.service loaded failed failed Backup service
OUTPUT
        ;;
    "show example.service --property=Id --property=Description --property=LoadState --property=ActiveState --property=SubState --no-pager")
        cat <<'OUTPUT'
Id=example.service
Description=Example background service
LoadState=loaded
ActiveState=failed
SubState=failed
OUTPUT
        ;;
    *)
        exit 1
        ;;
esac
EOF_SYSTEMCTL

chmod +x "${MOCK_BIN}/systemctl"

cat > "${MOCK_BIN}/systemd-analyze" <<'EOF_SYSTEMD_ANALYZE'
#!/usr/bin/env bash

case "$*" in
    "time --no-pager")
        cat <<'OUTPUT'
Startup finished in 7.381s (firmware) + 4.489s (loader) + 5.459s (kernel) + 13.367s (userspace) = 30.698s
graphical.target reached after 13.100s in userspace.
OUTPUT
        ;;
    "blame --no-pager")
        cat <<'OUTPUT'
5.432s NetworkManager-wait-online.service
1.250s docker.service
800ms cups.service
300ms systemd-journal-flush.service
100ms user-runtime-dir@1000.service
50ms dev-nvme0n1p3.device
OUTPUT
        ;;
    *)
        exit 1
        ;;
esac
EOF_SYSTEMD_ANALYZE

chmod +x "${MOCK_BIN}/systemd-analyze"

printf '%s\n' "openrc-init" > "${TEST_PROC_ROOT}/1/comm"

# shellcheck source=../src/core/service_metrics.sh
source "${PROJECT_ROOT}/src/core/service_metrics.sh"

printf '%s\n\n' "Running service metrics tests..."

assert_equals \
    "Available service tools are detected" \
    "available" \
    "$(get_service_tool_status systemctl)"

assert_equals \
    "Missing service tools are reported" \
    "not installed" \
    "$(get_service_tool_status lac-missing-service-tool)"

assert_equals \
    "Systemd is detected from process one" \
    "systemd" \
    "$(get_init_system)"

assert_equals \
    "The proc filesystem is used as an init fallback" \
    "openrc" \
    "$(
        is_service_tool_available() {
            [[ "$1" != "ps" ]]
        }

        get_init_system
    )"

assert_equals \
    "Degraded systemd states are preserved" \
    "degraded" \
    "$(get_systemd_system_state)"

assert_equals \
    "Non-systemd systems are reported as unsupported" \
    "unsupported" \
    "$(
        get_init_system() {
            printf '%s\n' "openrc"
        }

        get_systemd_system_state
    )"

assert_equals \
    "Missing systemctl is reported as unavailable" \
    "unavailable" \
    "$(
        get_init_system() {
            printf '%s\n' "systemd"
        }

        is_service_tool_available() {
            [[ "$1" != "systemctl" ]]
        }

        get_systemd_system_state
    )"

assert_equals \
    "Failed systemd services are listed" \
    $'example.service\nbackup.service' \
    "$(get_failed_systemd_services)"

assert_equals \
    "Failed systemd services are counted" \
    "2" \
    "$(get_failed_systemd_service_count)"

assert_equals \
    "Systemd service states are counted" \
    "active=1|inactive=1|failed=1" \
    "$(get_systemd_service_counts)"

assert_equals \
    "Systems without failed services report none" \
    "none" \
    "$(
        get_init_system() {
            printf '%s\n' "systemd"
        }

        systemctl() {
            return 0
        }

        get_failed_systemd_services
    )"

assert_equals \
    "Failed service details are parsed" \
    "unit=example.service|description=Example background service|load=loaded|active=failed|sub=failed" \
    "$(get_systemd_failed_service_details example.service)"

assert_equals \
    "Invalid service names are rejected" \
    "invalid service" \
    "$(get_systemd_failed_service_details "../example.service")"

assert_equals \
    "Total systemd boot time is detected" \
    "30.698s" \
    "$(get_systemd_boot_time)"

assert_equals \
    "Slowest systemd services are limited and formatted" \
    $'NetworkManager-wait-online.service|5.432s\ndocker.service|1.250s\ncups.service|800ms' \
    "$(get_slowest_systemd_services 3)"

assert_equals \
    "Invalid slow-service limits are rejected" \
    "invalid limit" \
    "$(get_slowest_systemd_services 0)"

assert_equals \
    "Boot analysis is unsupported on non-systemd systems" \
    "unsupported" \
    "$(
        get_init_system() {
            printf '%s\n' "openrc"
        }

        get_systemd_boot_time
    )"

assert_equals \
    "Missing systemd-analyze is reported as unavailable" \
    "unavailable" \
    "$(
        get_init_system() {
            printf '%s\n' "systemd"
        }

        is_service_tool_available() {
            [[ "$1" != "systemd-analyze" ]]
        }

        get_systemd_boot_time
    )"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
