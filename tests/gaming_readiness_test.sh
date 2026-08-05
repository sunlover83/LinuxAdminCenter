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

# shellcheck source=../src/modules/gaming_readiness/gaming_readiness.sh
source "${PROJECT_ROOT}/src/modules/gaming_readiness/gaming_readiness.sh"

get_display_server() {
    printf '%s\n' "wayland"
}

get_desktop_environment() {
    printf '%s\n' "COSMIC"
}

get_graphics_drivers() {
    printf '%s\n' "nvidia"
}

get_nvidia_driver_version() {
    printf '%s\n' "575.64.03"
}

get_vulkan_status() {
    printf '%s\n' "available"
}

get_steam_status() {
    printf '%s\n' "available (native)"
}

get_proton_compatibility_tools() {
    printf '%s\n' \
        "GE-Proton9-1" \
        "Proton-Example"
}

get_gaming_tool_status() {
    case "$1" in
        gamemoderun|mangohud|gamescope)
            printf '%s\n' "available"
            ;;
        *)
            printf '%s\n' "not installed"
            ;;
    esac
}

printf '%s\n\n' "Running gaming readiness tests..."

assert_equals \
    "Complete core requirements produce a ready status" \
    "ready" \
    "$(
        get_gaming_readiness_summary \
            "wayland" \
            "nvidia" \
            "available" \
            "available (native)"
    )"

assert_equals \
    "A missing Steam installation produces a limited status" \
    "limited" \
    "$(
        get_gaming_readiness_summary \
            "wayland" \
            "amdgpu" \
            "available" \
            "not installed"
    )"

assert_equals \
    "Missing Vulkan support produces a limited status" \
    "limited" \
    "$(
        get_gaming_readiness_summary \
            "x11" \
            "nvidia" \
            "unavailable" \
            "available (flatpak)"
    )"

assert_equals \
    "Unverified Vulkan support produces a limited status" \
    "limited" \
    "$(
        get_gaming_readiness_summary \
            "wayland" \
            "nvidia" \
            "not verified" \
            "available (native)"
    )"

assert_equals \
    "A missing graphical session produces an incomplete status" \
    "incomplete" \
    "$(
        get_gaming_readiness_summary \
            "unknown" \
            "nvidia" \
            "available" \
            "available (native)"
    )"

assert_equals \
    "An unknown graphics driver produces an incomplete status" \
    "incomplete" \
    "$(
        get_gaming_readiness_summary \
            "wayland" \
            "unknown" \
            "available" \
            "available (native)"
    )"

assert_equals \
    "Missing Vulkan and Steam produce an incomplete status" \
    "incomplete" \
    "$(
        get_gaming_readiness_summary \
            "wayland" \
            "amdgpu" \
            "not installed" \
            "not installed"
    )"

assert_equals \
    "Ready systems receive a successful explanation" \
    "Core gaming requirements are available." \
    "$(
        get_gaming_readiness_summary_message \
            "wayland" \
            "nvidia" \
            "available" \
            "available (native)"
    )"

assert_equals \
    "Missing Steam receives an explanatory message" \
    "Vulkan is available, but Steam is not installed." \
    "$(
        get_gaming_readiness_summary_message \
            "wayland" \
            "amdgpu" \
            "available" \
            "not installed"
    )"

assert_equals \
    "Unverified Vulkan support receives an explanatory message" \
    "Steam is installed, but Vulkan could not be verified because vulkaninfo is not installed." \
    "$(
        get_gaming_readiness_summary_message \
            "wayland" \
            "nvidia" \
            "not verified" \
            "available (native)"
    )"

assert_equals \
    "Missing graphical sessions receive an explanatory message" \
    "No Wayland or X11 graphical session was detected." \
    "$(
        get_gaming_readiness_summary_message \
            "unknown" \
            "nvidia" \
            "available" \
            "available (native)"
    )"

readiness_output="$(print_gaming_readiness)"

assert_output_contains \
    "Gaming readiness displays the session type" \
    "Display server:          wayland" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays the desktop environment" \
    "Desktop environment:     COSMIC" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays graphics drivers" \
    "Graphics driver(s):      nvidia" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays the NVIDIA driver version" \
    "NVIDIA driver version:   575.64.03" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays Vulkan support" \
    "Vulkan:                  available" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays Steam status" \
    "Steam:                   available (native)" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays custom Proton tools" \
    "GE-Proton9-1" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays GameMode status" \
    "GameMode:                available" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays MangoHud status" \
    "MangoHud:                available" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays Gamescope status" \
    "Gamescope:               available" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays the overall status" \
    "Status:                  ready" \
    "$readiness_output"

assert_output_contains \
    "Gaming readiness displays assessment details" \
    "Details:                 Core gaming requirements are available." \
    "$readiness_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
