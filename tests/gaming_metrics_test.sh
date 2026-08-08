#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"
TEST_HOME="${TEST_TMP_DIR}/home"
ORIGINAL_PATH="$PATH"

mkdir -p "$MOCK_BIN" "$TEST_HOME"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${ORIGINAL_PATH}"
export LAC_HOME_DIR="$TEST_HOME"

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

cat > "${MOCK_BIN}/lspci" <<'EOF_LSPCI'
#!/usr/bin/env bash

cat <<'OUTPUT'
01:00.0 VGA compatible controller: NVIDIA Corporation Device
	Subsystem: Example NVIDIA Device
	Kernel driver in use: nvidia
	Kernel modules: nouveau, nvidia_drm, nvidia
05:00.0 Display controller: Advanced Micro Devices, Inc. Device
	Subsystem: Example AMD Device
	Kernel driver in use: amdgpu
	Kernel modules: amdgpu
OUTPUT
EOF_LSPCI

chmod +x "${MOCK_BIN}/lspci"

cat > "${MOCK_BIN}/nvidia-smi" <<'EOF_NVIDIA'
#!/usr/bin/env bash

if [[ "$*" == "--query-gpu=driver_version --format=csv,noheader" ]]; then
    printf '%s\n' "550.78"
    exit 0
fi

exit 1
EOF_NVIDIA

chmod +x "${MOCK_BIN}/nvidia-smi"

cat > "${MOCK_BIN}/vulkaninfo" <<'EOF_VULKAN'
#!/usr/bin/env bash

[[ "$*" == "--summary" ]]
EOF_VULKAN

chmod +x "${MOCK_BIN}/vulkaninfo"

cat > "${MOCK_BIN}/steam" <<'EOF_STEAM'
#!/usr/bin/env bash

exit 0
EOF_STEAM

chmod +x "${MOCK_BIN}/steam"

for tool_name in gamemoderun mangohud gamescope; do
    cat > "${MOCK_BIN}/${tool_name}" <<'EOF_TOOL'
#!/usr/bin/env bash

exit 0
EOF_TOOL

    chmod +x "${MOCK_BIN}/${tool_name}"
done

mkdir -p \
    "${TEST_HOME}/.local/share/Steam/compatibilitytools.d/GE-Proton9-1" \
    "${TEST_HOME}/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/Proton-Example"

# shellcheck source=../src/core/gaming_metrics.sh
source "${PROJECT_ROOT}/src/core/gaming_metrics.sh"

printf '%s\n\n' "Running gaming metrics tests..."

assert_equals \
    "Wayland sessions are detected from XDG_SESSION_TYPE" \
    "wayland" \
    "$(XDG_SESSION_TYPE=WAYLAND get_display_server)"

assert_equals \
    "X11 sessions are detected from DISPLAY" \
    "x11" \
    "$(
        XDG_SESSION_TYPE='' \
        WAYLAND_DISPLAY='' \
        DISPLAY=:0 \
        get_display_server
    )"

assert_equals \
    "Desktop environments are detected" \
    "GNOME" \
    "$(XDG_CURRENT_DESKTOP=GNOME get_desktop_environment)"

assert_equals \
    "Multiple graphics drivers are reported" \
    "nvidia, amdgpu" \
    "$(get_graphics_drivers)"

assert_equals \
    "NVIDIA driver version is detected" \
    "550.78" \
    "$(get_nvidia_driver_version)"

assert_equals \
    "Working Vulkan support is detected" \
    "available" \
    "$(get_vulkan_status)"

assert_equals \
    "Missing vulkaninfo is reported as not verified" \
    "not verified" \
    "$(
        is_gaming_tool_available() {
            [[ "$1" != "vulkaninfo" ]]
        }

        get_vulkan_status
    )"

assert_equals \
    "Native Steam installations are detected" \
    "available (native)" \
    "$(get_steam_status)"

rm -f "${MOCK_BIN}/steam"

cat > "${MOCK_BIN}/flatpak" <<'EOF_FLATPAK'
#!/usr/bin/env bash

if [[ "$*" == "info com.valvesoftware.Steam" ]]; then
    exit 0
fi

exit 1
EOF_FLATPAK

chmod +x "${MOCK_BIN}/flatpak"

assert_equals \
    "Flatpak Steam installations are detected" \
    "available (flatpak)" \
    "$(
        is_gaming_tool_available() {
            [[ "$1" == "flatpak" ]]
        }

        get_steam_status
    )"

assert_equals \
    "Custom Proton tools are detected across installations" \
    $'GE-Proton9-1\nProton-Example' \
    "$(get_proton_compatibility_tools)"

assert_equals \
    "GameMode availability is detected" \
    "available" \
    "$(get_gaming_tool_status gamemoderun)"

assert_equals \
    "MangoHud availability is detected" \
    "available" \
    "$(get_gaming_tool_status mangohud)"

assert_equals \
    "Gamescope availability is detected" \
    "available" \
    "$(get_gaming_tool_status gamescope)"

assert_equals \
    "Missing gaming tools are reported" \
    "not installed" \
    "$(get_gaming_tool_status lac-missing-gaming-tool)"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
