#!/usr/bin/env bash

is_steam_available_status() {
    local steam_status="$1"

    case "$steam_status" in
        available*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_gaming_readiness_summary() {
    local display_server="$1"
    local graphics_drivers="$2"
    local vulkan_status="$3"
    local steam_status="$4"

    case "$display_server" in
        wayland|x11)
            ;;
        *)
            printf '%s\n' "incomplete"
            return
            ;;
    esac

    case "$graphics_drivers" in
        ""|unavailable|unknown)
            printf '%s\n' "incomplete"
            return
            ;;
    esac

    if [[ "$vulkan_status" == "available" ]] &&
        is_steam_available_status "$steam_status"; then
        printf '%s\n' "ready"
        return
    fi

    if [[ "$vulkan_status" != "available" ]] &&
        ! is_steam_available_status "$steam_status"; then
        printf '%s\n' "incomplete"
        return
    fi

    printf '%s\n' "limited"
}

get_gaming_readiness_summary_message() {
    local display_server="$1"
    local graphics_drivers="$2"
    local vulkan_status="$3"
    local steam_status="$4"
    local readiness_status

    readiness_status="$(
        get_gaming_readiness_summary \
            "$display_server" \
            "$graphics_drivers" \
            "$vulkan_status" \
            "$steam_status"
    )"

    if [[ "$readiness_status" == "ready" ]]; then
        printf '%s\n' "Core gaming requirements are available."
        return
    fi

    case "$display_server" in
        wayland|x11)
            ;;
        *)
            printf '%s\n' \
                "No Wayland or X11 graphical session was detected."
            return
            ;;
    esac

    case "$graphics_drivers" in
        ""|unavailable|unknown)
            printf '%s\n' \
                "The active graphics driver could not be determined."
            return
            ;;
    esac

    if [[ "$vulkan_status" != "available" ]] &&
        ! is_steam_available_status "$steam_status"; then
        printf '%s\n' \
            "Vulkan support and a Steam installation could not be confirmed."
        return
    fi

    if [[ "$vulkan_status" == "not verified" ]]; then
    printf '%s\n' \
        "Steam is installed, but Vulkan could not be verified because vulkaninfo is not installed."
    return
    fi

    if [[ "$vulkan_status" != "available" ]]; then
        printf '%s\n' \
            "Steam is installed, but Vulkan support is missing or unavailable."
        return
    fi

    if ! is_steam_available_status "$steam_status"; then
        printf '%s\n' \
            "Vulkan is available, but Steam is not installed."
        return
    fi

    printf '%s\n' \
        "One or more core gaming requirements could not be confirmed."
}

print_gaming_readiness() {
    local display_server
    local desktop_environment
    local graphics_drivers
    local nvidia_driver_version
    local vulkan_status
    local steam_status
    local proton_tools
    local gamemode_status
    local mangohud_status
    local gamescope_status
    local readiness_status
    local readiness_details
    local proton_tool

    display_server="$(get_display_server)"
    desktop_environment="$(get_desktop_environment)"
    graphics_drivers="$(get_graphics_drivers)"
    nvidia_driver_version="$(get_nvidia_driver_version)"

    vulkan_status="$(get_vulkan_status)"
    steam_status="$(get_steam_status)"
    proton_tools="$(get_proton_compatibility_tools)"

    gamemode_status="$(get_gaming_tool_status gamemoderun)"
    mangohud_status="$(get_gaming_tool_status mangohud)"
    gamescope_status="$(get_gaming_tool_status gamescope)"

    readiness_status="$(
        get_gaming_readiness_summary \
            "$display_server" \
            "$graphics_drivers" \
            "$vulkan_status" \
            "$steam_status"
    )"

    readiness_details="$(
        get_gaming_readiness_summary_message \
            "$display_server" \
            "$graphics_drivers" \
            "$vulkan_status" \
            "$steam_status"
    )"

    printf '%s\n' "Gaming environment:"
    printf '  Display server:          %s\n' "$display_server"
    printf '  Desktop environment:     %s\n' "$desktop_environment"
    printf '  Graphics driver(s):      %s\n' "$graphics_drivers"
    printf '  NVIDIA driver version:   %s\n' "$nvidia_driver_version"
    echo

    printf '%s\n' "Gaming platform:"
    printf '  Vulkan:                  %s\n' "$vulkan_status"
    printf '  Steam:                   %s\n' "$steam_status"
    printf '%s\n' "  Custom Proton tools:"

    while IFS= read -r proton_tool; do
        if [[ -n "$proton_tool" ]]; then
            printf '    %s\n' "$proton_tool"
        fi
    done <<< "$proton_tools"

    echo
    printf '%s\n' "Optional gaming tools:"
    printf '  GameMode:                %s\n' "$gamemode_status"
    printf '  MangoHud:                %s\n' "$mangohud_status"
    printf '  Gamescope:               %s\n' "$gamescope_status"

    echo
    printf '%s\n' "Overall assessment:"
    printf '  Status:                  %s\n' "$readiness_status"
    printf '  Details:                 %s\n' "$readiness_details"
}

show_gaming_readiness() {
    draw_module_header "Gaming Readiness"

    log_info "Reading gaming environment..."
    echo

    print_gaming_readiness

    echo
    read -rp "Press Enter to continue..."
}
