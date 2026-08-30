#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAC_SCRIPT="${PROJECT_ROOT}/src/lac.sh"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"
LSCPU_FIXTURE="${TEST_TMP_DIR}/lscpu.txt"
CPUINFO_FIXTURE="${TEST_TMP_DIR}/cpuinfo.txt"

mkdir -p "$MOCK_BIN"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${PATH}"
export LSCPU_FIXTURE

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

assert_output_not_contains() {
    local description="$1"
    local unexpected="$2"
    local output
    local status

    shift 2

    if output=$("$@" 2>&1); then
        status=0
    else
        status=$?
    fi

    if (( status == 0 )) &&
        [[ "$output" != *"$unexpected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Unexpected: %s\n' "$unexpected"
        printf '       Output:     %s\n' "$output"
        printf '       Status:     %s\n' "$status"
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

cat > "${MOCK_BIN}/lscpu" <<'EOF'
#!/usr/bin/env bash

cat "$LSCPU_FIXTURE"
EOF

cat > "${MOCK_BIN}/uname" <<'EOF'
#!/usr/bin/env bash

case "${1:-}" in
    -p)
        printf '%s\n' "unknown"
        ;;
    -m)
        printf '%s\n' "aarch64"
        ;;
    -r)
        printf '%s\n' "6.8.0-test"
        ;;
    *)
        printf '%s\n' "test-system"
        ;;
esac
EOF

cat > "$LSCPU_FIXTURE" <<'EOF'
Architecture:                         x86_64
CPU(s):                               32
Model name:                           Test Processor 9000
EOF

chmod +x "${MOCK_BIN}/lscpu" "${MOCK_BIN}/uname"

# shellcheck source=../src/core/system_metrics.sh
source "${PROJECT_ROOT}/src/core/system_metrics.sh"

# shellcheck source=../src/modules/system_info/system_info.sh
source "${PROJECT_ROOT}/src/modules/system_info/system_info.sh"

printf '%s\n\n' "Running system information tests..."

assert_equals \
    "CPU model is read from lscpu" \
    "Test Processor 9000" \
    "$(get_cpu_model)"

cat > "$LSCPU_FIXTURE" <<'EOF'
Architecture:                         aarch64
CPU(s):                               4
Model name:                           -
EOF

cat > "$CPUINFO_FIXTURE" <<'EOF'
processor       : 0
Processor       : -
CPU implementer : 0x41
CPU architecture: 8
Hardware        : Example ARM64 Platform
EOF

assert_equals \
    "ARM64 placeholder falls back to cpuinfo hardware" \
    "Example ARM64 Platform" \
    "$(get_cpu_model "$CPUINFO_FIXTURE")"

: > "$CPUINFO_FIXTURE"

assert_equals \
    "Missing ARM64 model data falls back to the architecture" \
    "aarch64" \
    "$(get_cpu_model "$CPUINFO_FIXTURE")"

cat > "$LSCPU_FIXTURE" <<'EOF'
Architecture:                         x86_64
CPU(s):                               32
Model name:                           Test Processor 9000
EOF

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
    "System information includes the CPU model" \
    "CPU:              Test Processor 9000" \
    "$LAC_SCRIPT" \
    --system-info

assert_output_contains \
    "System information includes the logical CPU count" \
    "Logical CPUs:" \
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

assert_output_not_contains \
    "System information does not duplicate network details" \
    "IPv4 addresses:" \
    "$LAC_SCRIPT" \
    --system-info

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
