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

# shellcheck source=../src/modules/gaming_diagnostics/gaming_diagnostics.sh
source "${PROJECT_ROOT}/src/modules/gaming_diagnostics/gaming_diagnostics.sh"

get_vulkan_status() {
    printf '%s\n' "available"
}

get_vulkan_instance_version() {
    printf '%s\n' "1.4.309"
}

get_vulkan_32bit_loader_status() {
    printf '%s\n' "available"
}

get_vulkan_device_records() {
    printf '%s\n' \
        "device=NVIDIA GeForce RTX 4070|driver=NVIDIA|api=1.4.303"
}

get_steam_status() {
    printf '%s\n' "available (native)"
}

get_steam_launch_target() {
    printf '%s\n' "/usr/bin/steam"
}

get_steam_library_roots() {
    printf '%s\n' \
        "/home/test/.local/share/Steam" \
        "/mnt/games/SteamLibrary"
}

get_steam_compatdata_count() {
    printf '%s\n' "12"
}

get_installed_proton_runtimes() {
    printf '%s\n' \
        "bundled|Proton 9.0" \
        "custom|GE-Proton9-1"
}

get_gaming_tool_status() {
    case "$1" in
        gamemoderun|mangohud|gamescope)
            printf '%s\n' "available"
            ;;
        mangoapp)
            printf '%s\n' "not installed"
            ;;
        *)
            printf '%s\n' "not installed"
            ;;
    esac
}

get_gamescope_version() {
    printf '%s\n' "gamescope version 3.16.1"
}

printf '%s\n\n' "Running gaming diagnostics tests..."

assert_equals \
    "Complete gaming diagnostics are healthy" \
    "healthy" \
    "$(
        get_gaming_diagnostics_summary \
            "available" \
            "available (native)" \
            "available" \
            "bundled|Proton 9.0"
    )"

assert_equals \
    "Flatpak-managed 32-bit graphics support is healthy" \
    "healthy" \
    "$(
        get_gaming_diagnostics_summary \
            "available" \
            "available (flatpak)" \
            "managed by Flatpak" \
            "bundled|Proton 9.0"
    )"

assert_equals \
    "Flatpak Steam overrides host 32-bit loader status" \
    "managed by Flatpak" \
    "$(
        get_effective_vulkan_32bit_status \
            "available (flatpak)" \
            "not verified"
    )"

assert_equals \
    "Native Steam preserves host 32-bit loader status" \
    "not verified" \
    "$(
        get_effective_vulkan_32bit_status \
            "available (native)" \
            "not verified"
    )"

assert_equals \
    "Missing 32-bit Vulkan verification produces a warning" \
    "warning" \
    "$(
        get_gaming_diagnostics_summary \
            "available" \
            "available (native)" \
            "not verified" \
            "bundled|Proton 9.0"
    )"

assert_equals \
    "Missing Proton runtimes produce a warning" \
    "warning" \
    "$(
        get_gaming_diagnostics_summary \
            "available" \
            "available (native)" \
            "available" \
            "none"
    )"

assert_equals \
    "Missing Steam produces incomplete diagnostics" \
    "incomplete" \
    "$(
        get_gaming_diagnostics_summary \
            "available" \
            "not installed" \
            "available" \
            "none"
    )"

assert_equals \
    "Unavailable Vulkan produces incomplete diagnostics" \
    "incomplete" \
    "$(
        get_gaming_diagnostics_summary \
            "unavailable" \
            "available (native)" \
            "available" \
            "bundled|Proton 9.0"
    )"

assert_equals \
    "Healthy diagnostics receive an explanatory message" \
    "Steam, Vulkan, 32-bit graphics support and installed Proton runtimes were detected." \
    "$(
        get_gaming_diagnostics_summary_message \
            "available" \
            "available (native)" \
            "available" \
            "bundled|Proton 9.0"
    )"

assert_equals \
    "Missing 32-bit Vulkan receives an explanatory message" \
    "Steam and Vulkan are available, but 32-bit Vulkan support could not be verified." \
    "$(
        get_gaming_diagnostics_summary_message \
            "available" \
            "available (native)" \
            "not verified" \
            "bundled|Proton 9.0"
    )"

assert_equals \
    "Device records are parsed" \
    "NVIDIA GeForce RTX 4070" \
    "$(
        get_gaming_diagnostic_record_value \
            "device=NVIDIA GeForce RTX 4070|driver=NVIDIA|api=1.4.303" \
            device
    )"

diagnostics_output="$(print_gaming_diagnostics)"

assert_output_contains \
    "Gaming diagnostics display Vulkan status" \
    "Runtime:                 available" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display the Vulkan instance version" \
    "Instance version:        1.4.309" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display 32-bit Vulkan support" \
    "32-bit Vulkan support:   available" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display Vulkan devices" \
    "NVIDIA GeForce RTX 4070" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display Vulkan drivers" \
    "Driver:              NVIDIA" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display the Steam launch target" \
    "Launch target:           /usr/bin/steam" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display compatibility prefix counts" \
    "Compatibility prefixes: 12" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display additional Steam libraries" \
    "/mnt/games/SteamLibrary" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display bundled Proton runtimes" \
    "Proton 9.0" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display custom Proton runtimes" \
    "GE-Proton9-1" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display MangoApp status" \
    "MangoApp:                not installed" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display the Gamescope version" \
    "Gamescope version:       gamescope version 3.16.1" \
    "$diagnostics_output"

assert_output_contains \
    "Gaming diagnostics display a healthy assessment" \
    "Status:                  healthy" \
    "$diagnostics_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
