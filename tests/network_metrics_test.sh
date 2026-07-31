#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAC_SCRIPT="${PROJECT_ROOT}/src/lac.sh"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"

mkdir -p "$MOCK_BIN"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${PATH}"

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
    local output
    local status

    shift 2

    if output=$("$@" 2>&1); then
        status=0
    else
        status=$?
    fi

    if (( status == 0 )) &&
        [[ "$output" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Output:   %s\n' "$output"
        printf '       Status:   %s\n' "$status"
    fi
}

cat > "${MOCK_BIN}/ip" <<'EOF'
#!/usr/bin/env bash

case "$*" in
    "-o link show up")
        cat <<'OUTPUT'
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 state UNKNOWN
2: enp5s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 state UP
3: wlan0@phy0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 state UP
OUTPUT
        ;;
    "-o -4 addr show scope global")
        cat <<'OUTPUT'
2: enp5s0    inet 192.168.1.50/24 brd 192.168.1.255 scope global enp5s0
3: wlan0     inet 10.0.0.20/24 brd 10.0.0.255 scope global wlan0
OUTPUT
        ;;
    "-4 route show default")
        printf '%s\n' \
            "default via 192.168.1.1 dev enp5s0 proto dhcp"
        ;;
    *)
        exit 1
        ;;
esac
EOF

chmod +x "${MOCK_BIN}/ip"

cat > "${MOCK_BIN}/resolvectl" <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" == "dns" ]]; then
    cat <<'OUTPUT'
Global: 1.1.1.1
Link 2 (enp5s0): 192.168.1.1
Link 3 (wlan0): 1.1.1.1
OUTPUT
    exit 0
fi

exit 1
EOF

chmod +x "${MOCK_BIN}/resolvectl"

# shellcheck source=../src/core/network_metrics.sh
source "${PROJECT_ROOT}/src/core/network_metrics.sh"

printf '%s\n\n' "Running network metrics tests..."

assert_equals \
    "Active network interfaces are detected" \
    "enp5s0; wlan0" \
    "$(get_active_network_interfaces)"

assert_equals \
    "IPv4 addresses are assigned to their interfaces" \
    "enp5s0: 192.168.1.50/24; wlan0: 10.0.0.20/24" \
    "$(get_ipv4_addresses)"

assert_equals \
    "Default gateway and interface are detected" \
    "192.168.1.1 via enp5s0" \
    "$(get_default_gateway)"

assert_equals \
    "DNS servers are detected without duplicates" \
    "1.1.1.1; 192.168.1.1" \
    "$(get_dns_servers)"

assert_output_contains \
    "System information includes active interfaces" \
    "Interfaces:       enp5s0; wlan0" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes IPv4 addresses" \
    "IPv4 addresses:   enp5s0: 192.168.1.50/24" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes the default gateway" \
    "Default gateway:  192.168.1.1 via enp5s0" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes DNS servers" \
    "DNS servers:      1.1.1.1; 192.168.1.1" \
    "$LAC_SCRIPT" \
    --system-info

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
