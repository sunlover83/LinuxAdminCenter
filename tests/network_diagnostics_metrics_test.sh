#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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

cat > "${MOCK_BIN}/ip" <<'EOF_IP'
#!/usr/bin/env bash

if [[ "$*" == "-4 route show default" ]]; then
    printf '%s\n' \
        "default via 192.168.1.1 dev enp5s0 proto dhcp"
    exit 0
fi

exit 1
EOF_IP

chmod +x "${MOCK_BIN}/ip"

cat > "${MOCK_BIN}/ping" <<'EOF_PING'
#!/usr/bin/env bash

target="${*: -1}"

case "$target" in
    192.168.1.1)
        cat <<'OUTPUT'
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=1.100 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=1.200 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=64 time=1.400 ms

--- 192.168.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 1.100/1.233/1.400/0.125 ms
OUTPUT
        ;;
    1.1.1.1)
        cat <<'OUTPUT'
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=57 time=12.100 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=57 time=12.500 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=57 time=12.900 ms

--- 1.1.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2001ms
rtt min/avg/max/mdev = 12.100/12.500/12.900/0.326 ms
OUTPUT
        ;;
    203.0.113.1)
        cat <<'OUTPUT'
PING 203.0.113.1 (203.0.113.1) 56(84) bytes of data.

--- 203.0.113.1 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2044ms
OUTPUT
        exit 1
        ;;
    *)
        exit 2
        ;;
esac
EOF_PING

chmod +x "${MOCK_BIN}/ping"

cat > "${MOCK_BIN}/getent" <<'EOF_GETENT'
#!/usr/bin/env bash

if [[ "$*" == "ahosts example.com" ]]; then
    cat <<'OUTPUT'
93.184.216.34  STREAM example.com
93.184.216.34  DGRAM
93.184.216.34  RAW
OUTPUT
    exit 0
fi

exit 2
EOF_GETENT

chmod +x "${MOCK_BIN}/getent"

# shellcheck source=../src/core/network_diagnostics_metrics.sh
source "${PROJECT_ROOT}/src/core/network_diagnostics_metrics.sh"

printf '%s\n\n' "Running network diagnostics metrics tests..."

assert_equals \
    "Available diagnostic tools are detected" \
    "available" \
    "$(get_network_diagnostic_tool_status ping)"

assert_equals \
    "Missing diagnostic tools are reported" \
    "not installed" \
    "$(get_network_diagnostic_tool_status lac-missing-tool)"

assert_equals \
    "Default gateway address is detected" \
    "192.168.1.1" \
    "$(get_default_gateway_address)"

assert_equals \
    "Reachable targets include packet loss and latency" \
    "reachable|packet_loss=0%|average_latency=1.2 ms" \
    "$(get_ping_diagnostics 192.168.1.1)"

assert_equals \
    "Unreachable targets are reported" \
    "unreachable|packet_loss=100%|average_latency=unknown" \
    "$(get_ping_diagnostics 203.0.113.1)"

assert_equals \
    "Gateway connectivity uses the detected gateway" \
    "reachable|packet_loss=0%|average_latency=1.2 ms" \
    "$(get_gateway_connectivity)"

assert_equals \
    "DNS resolution succeeds for resolvable hosts" \
    "working" \
    "$(get_dns_resolution_status example.com)"

assert_equals \
    "DNS resolution failures are reported" \
    "failed" \
    "$(get_dns_resolution_status invalid.example)"

assert_equals \
    "Internet connectivity uses the configured test target" \
    "reachable|packet_loss=0%|average_latency=12.5 ms" \
    "$(get_internet_connectivity)"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
