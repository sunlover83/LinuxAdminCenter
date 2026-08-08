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

cat > "${MOCK_BIN}/sensors" <<'EOF'
#!/usr/bin/env bash

if [[ "${MOCK_SENSORS_FAILURE:-false}" == "true" ]]; then
    exit 1
fi

cat <<'OUTPUT'
k10temp-pci-00c3
Adapter: PCI adapter
Tctl:
  temp1_input: 47.640
  temp1_max: 90.000
  temp1_crit: 95.000

nvme-pci-0100
Adapter: PCI adapter
Composite:
  temp1_input: 34.250
OUTPUT
EOF

chmod +x "${MOCK_BIN}/sensors"

cat > "${MOCK_BIN}/nvidia-smi" <<'EOF'
#!/usr/bin/env bash

if [[ "${MOCK_NVIDIA_FAILURE:-false}" == "true" ]]; then
    exit 1
fi

cat <<'OUTPUT'
0, NVIDIA GeForce RTX 3060, 52, 17, 2048, 12288
1, NVIDIA Test GPU, 46, 31, 1536, 8192
OUTPUT
EOF

chmod +x "${MOCK_BIN}/nvidia-smi"

cat > "${MOCK_BIN}/lsblk" <<'EOF'
#!/usr/bin/env bash

cat <<'OUTPUT'
sda disk 500107862016 Example SATA SSD 500GB
nvme0n1 disk 1000204886016 Example NVMe SSD 1TB
sde disk 0 SD/MMC/MS/MSPRO
zram0 disk 8589934592
loop0 loop 1048576 Loop Device
OUTPUT
EOF

chmod +x "${MOCK_BIN}/lsblk"

cat > "${MOCK_BIN}/smartctl" <<'EOF'
#!/usr/bin/env bash

cat <<'OUTPUT'
SMART overall-health self-assessment test result: PASSED
OUTPUT
EOF

chmod +x "${MOCK_BIN}/smartctl"

cat > "${MOCK_BIN}/nvme" <<'EOF'
#!/usr/bin/env bash

cat <<'OUTPUT'
critical_warning                    : 0
temperature                         : 35 °C
available_spare                     : 100%
OUTPUT
EOF

chmod +x "${MOCK_BIN}/nvme"

# shellcheck source=../src/core/hardware_metrics.sh
source "${PROJECT_ROOT}/src/core/hardware_metrics.sh"

get_cpu_temperature_without_tool() (
    is_hardware_tool_available() {
        return 1
    }

    get_cpu_temperature
)

get_nvidia_diagnostics_without_tool() (
    is_hardware_tool_available() {
        return 1
    }

    get_nvidia_gpu_diagnostics
)

printf '%s\n\n' "Running hardware metrics tests..."

assert_equals \
    "Installed hardware tools are detected" \
    "available" \
    "$(get_hardware_tool_status sensors)"

assert_equals \
    "Missing hardware tools are reported" \
    "not installed" \
    "$(get_hardware_tool_status definitely-not-installed)"

assert_equals \
    "Whitespace is removed from hardware values" \
    "NVIDIA GeForce RTX 3060" \
    "$(trim_hardware_value "   NVIDIA GeForce RTX 3060   ")"

assert_equals \
    "CPU temperature is detected and formatted" \
    "47.6 °C" \
    "$(get_cpu_temperature)"

assert_equals \
    "Multiple NVIDIA GPUs are reported" \
    "$(cat <<'EXPECTED'
GPU 0: NVIDIA GeForce RTX 3060 | 52 °C | 17% | 2048 MiB / 12288 MiB
GPU 1: NVIDIA Test GPU | 46 °C | 31% | 1536 MiB / 8192 MiB
EXPECTED
)" \
    "$(get_nvidia_gpu_diagnostics)"

assert_equals \
    "Storage devices are detected without loop devices" \
    "$(cat <<'EXPECTED'
/dev/sda|Example SATA SSD 500GB
/dev/nvme0n1|Example NVMe SSD 1TB
EXPECTED
)" \
    "$(get_storage_devices)"

assert_equals \
    "SMART health is detected" \
    "healthy" \
    "$(get_smart_health_status /dev/sda)"

assert_equals \
    "NVMe health is detected" \
    "healthy" \
    "$(get_nvme_health_status /dev/nvme0n1)"

assert_equals \
    "Storage diagnostics use the correct health tool" \
    "$(cat <<'EXPECTED'
/dev/sda: Example SATA SSD 500GB | SMART health: healthy
/dev/nvme0n1: Example NVMe SSD 1TB | NVMe health: healthy
EXPECTED
)" \
    "$(get_storage_diagnostics)"

export MOCK_SENSORS_FAILURE=true

assert_equals \
    "A failed sensors command returns unknown" \
    "unknown" \
    "$(get_cpu_temperature)"

unset MOCK_SENSORS_FAILURE

export MOCK_NVIDIA_FAILURE=true

assert_equals \
    "A failed NVIDIA query returns unknown" \
    "unknown" \
    "$(get_nvidia_gpu_diagnostics)"

unset MOCK_NVIDIA_FAILURE

assert_equals \
    "Missing CPU sensor support returns unavailable" \
    "unavailable" \
    "$(get_cpu_temperature_without_tool)"

assert_equals \
    "Missing NVIDIA support returns unavailable" \
    "unavailable" \
    "$(get_nvidia_diagnostics_without_tool)"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
