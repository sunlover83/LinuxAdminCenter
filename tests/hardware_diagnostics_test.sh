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

# shellcheck source=../src/modules/hardware_diagnostics/hardware_diagnostics.sh
source "${PROJECT_ROOT}/src/modules/hardware_diagnostics/hardware_diagnostics.sh"

get_hardware_tool_status() {
    case "$1" in
        sensors|nvidia-smi|smartctl|nvme)
            printf '%s\n' "available"
            ;;
        *)
            printf '%s\n' "not installed"
            ;;
    esac
}

get_cpu_temperature() {
    printf '%s\n' "47.6 °C"
}

get_nvidia_gpu_diagnostics() {
    cat <<'OUTPUT'
GPU 0: NVIDIA GeForce RTX 3060 | 52 °C | 17% | 2048 MiB / 12288 MiB
OUTPUT
}

get_storage_diagnostics() {
    cat <<'OUTPUT'
/dev/sda: Example SATA SSD 500GB | SMART health: healthy
/dev/nvme0n1: Example NVMe SSD 1TB | NVMe health: healthy
OUTPUT
}

printf '%s\n\n' "Running hardware diagnostics tests..."

diagnostics_output="$(print_hardware_diagnostics)"

assert_output_contains \
    "Hardware diagnostics display sensor tool status" \
    "sensors:      available" \
    "$diagnostics_output"

assert_output_contains \
    "Hardware diagnostics display SMART tool status" \
    "smartctl:     available" \
    "$diagnostics_output"

assert_output_contains \
    "Hardware diagnostics display CPU temperature" \
    "CPU:          47.6 °C" \
    "$diagnostics_output"

assert_output_contains \
    "Hardware diagnostics display NVIDIA information" \
    "GPU 0: NVIDIA GeForce RTX 3060" \
    "$diagnostics_output"

assert_output_contains \
    "Hardware diagnostics display SATA health" \
    "/dev/sda: Example SATA SSD 500GB | SMART health: healthy" \
    "$diagnostics_output"

assert_output_contains \
    "Hardware diagnostics display NVMe health" \
    "/dev/nvme0n1: Example NVMe SSD 1TB | NVMe health: healthy" \
    "$diagnostics_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
