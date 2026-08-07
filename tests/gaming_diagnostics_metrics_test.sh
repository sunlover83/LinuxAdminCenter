#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"
TEST_HOME="${TEST_TMP_DIR}/home"
TEST_ROOT="${TEST_TMP_DIR}/root"
ORIGINAL_PATH="$PATH"

mkdir -p "$MOCK_BIN" "$TEST_HOME" "$TEST_ROOT"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${ORIGINAL_PATH}"
export LAC_HOME_DIR="$TEST_HOME"
export LAC_ROOT_DIR="$TEST_ROOT"

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

cat > "${MOCK_BIN}/vulkaninfo" <<'EOF_VULKAN'
#!/usr/bin/env bash

if [[ "$*" == "--summary" ]]; then
    cat <<'OUTPUT'
VULKANINFO
Vulkan Instance Version: 1.4.309

Devices:
========
GPU0:
    apiVersion         = 1.4.303
    deviceName         = NVIDIA GeForce RTX 4070
    driverName         = NVIDIA
GPU1:
    apiVersion         = 1.3.290
    deviceName         = AMD Radeon Graphics
    driverName         = RADV
OUTPUT
    exit 0
fi

exit 1
EOF_VULKAN
chmod +x "${MOCK_BIN}/vulkaninfo"

cat > "${MOCK_BIN}/steam" <<'EOF_STEAM'
#!/usr/bin/env bash
exit 0
EOF_STEAM
chmod +x "${MOCK_BIN}/steam"

cat > "${MOCK_BIN}/gamescope" <<'EOF_GAMESCOPE'
#!/usr/bin/env bash
[[ "$*" == "--version" ]] || exit 1
printf '%s\n' "gamescope version 3.15.5"
EOF_GAMESCOPE
chmod +x "${MOCK_BIN}/gamescope"

mkdir -p \
    "${TEST_ROOT}/usr/lib32" \
    "${TEST_HOME}/.steam" \
    "${TEST_HOME}/.local/share/Steam/steamapps/common/Proton 9.0" \
    "${TEST_HOME}/.local/share/Steam/steamapps/compatdata/123" \
    "${TEST_HOME}/.local/share/Steam/steamapps/compatdata/456" \
    "${TEST_HOME}/.local/share/Steam/compatibilitytools.d/GE-Proton9-1" \
    "${TEST_HOME}/Games/SteamLibrary/steamapps/common/Proton Experimental" \
    "${TEST_HOME}/Games/SteamLibrary/steamapps/compatdata/123" \
    "${TEST_HOME}/Games/SteamLibrary/steamapps/compatdata/789"

ln -s ../.local/share/Steam "${TEST_HOME}/.steam/root"

touch \
    "${TEST_ROOT}/usr/lib32/libvulkan.so.1" \
    "${TEST_HOME}/.local/share/Steam/steamapps/common/Proton 9.0/proton" \
    "${TEST_HOME}/Games/SteamLibrary/steamapps/common/Proton Experimental/proton"

cat > "${TEST_HOME}/.local/share/Steam/steamapps/libraryfolders.vdf" <<EOF_LIBRARY
"libraryfolders"
{
    "0"
    {
        "path"    "${TEST_HOME}/.local/share/Steam"
    }
    "1"
    {
        "path"    "${TEST_HOME}/Games/SteamLibrary"
    }
}
EOF_LIBRARY

# shellcheck source=../src/core/gaming_metrics.sh
source "${PROJECT_ROOT}/src/core/gaming_metrics.sh"
# shellcheck source=../src/core/gaming_diagnostics_metrics.sh
source "${PROJECT_ROOT}/src/core/gaming_diagnostics_metrics.sh"

printf '%s\n\n' "Running gaming diagnostics metrics tests..."

assert_equals \
    "Vulkan instance versions are parsed" \
    "1.4.309" \
    "$(get_vulkan_instance_version)"

assert_equals \
    "Vulkan devices and drivers are parsed" \
    $'device=NVIDIA GeForce RTX 4070|driver=NVIDIA|api=1.4.303\ndevice=AMD Radeon Graphics|driver=RADV|api=1.3.290' \
    "$(get_vulkan_device_records)"

assert_equals \
    "Missing vulkaninfo prevents instance verification" \
    "not verified" \
    "$(
        is_gaming_tool_available() {
            [[ "$1" != "vulkaninfo" ]]
        }
        get_vulkan_instance_version
    )"

assert_equals \
    "Common 32-bit Vulkan loader paths are detected" \
    "available" \
    "$(get_vulkan_32bit_loader_status)"

rm -f "${TEST_ROOT}/usr/lib32/libvulkan.so.1"

assert_equals \
    "Missing 32-bit Vulkan loaders are reported conservatively" \
    "not verified" \
    "$(get_vulkan_32bit_loader_status)"

touch "${TEST_ROOT}/usr/lib32/libvulkan.so.1"

assert_equals \
    "Native Steam launch targets are detected" \
    "${MOCK_BIN}/steam" \
    "$(get_steam_launch_target)"

library_roots="$(get_steam_library_roots)"
assert_equals \
    "Equivalent native Steam roots are canonicalized" \
    "2" \
    "$(awk 'NF { count++ } END { print count + 0 }' <<< "$library_roots")"
assert_equals \
    "Default Steam libraries are detected" \
    "${TEST_HOME}/.local/share/Steam" \
    "$(sed -n '1p' <<< "$library_roots")"
assert_equals \
    "Additional Steam libraries are detected" \
    "${TEST_HOME}/Games/SteamLibrary" \
    "$(sed -n '2p' <<< "$library_roots")"

assert_equals \
    "Bundled and custom Proton runtimes are detected" \
    $'bundled|Proton 9.0\nbundled|Proton Experimental\ncustom|GE-Proton9-1' \
    "$(get_installed_proton_runtimes)"

assert_equals \
    "Compatibility prefixes are counted across libraries" \
    "3" \
    "$(get_steam_compatdata_count)"

assert_equals \
    "Gamescope versions are detected" \
    "gamescope version 3.15.5" \
    "$(get_gamescope_version)"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
