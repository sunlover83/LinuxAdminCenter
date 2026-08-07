#!/usr/bin/env bash

gaming_diagnostics_steam_available() {
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

get_effective_vulkan_32bit_status() {
    local steam_status="$1"
    local host_status="$2"

    if [[ "$steam_status" == "available (flatpak)" ]]; then
        printf '%s\n' "managed by Flatpak"
    else
        printf '%s\n' "$host_status"
    fi
}

get_gaming_diagnostic_record_value() {
    local record="$1"
    local key="$2"
    local field
    local -a fields=()

    case "$record" in
        none|unknown|unavailable|"not verified")
            printf '%s\n' "$record"
            return
            ;;
    esac

    IFS='|' read -r -a fields <<< "$record"

    for field in "${fields[@]}"; do
        if [[ "$field" == "${key}="* ]]; then
            printf '%s\n' "${field#*=}"
            return
        fi
    done

    printf '%s\n' "unknown"
}

get_gaming_diagnostics_summary() {
    local vulkan_status="$1"
    local steam_status="$2"
    local vulkan_32bit_status="$3"
    local proton_runtimes="$4"

    if [[ "$vulkan_status" != "available" ]] ||
        ! gaming_diagnostics_steam_available "$steam_status"; then
        printf '%s\n' "incomplete"
        return
    fi

    case "$vulkan_32bit_status" in
        available|"managed by Flatpak")
            ;;
        *)
            printf '%s\n' "warning"
            return
            ;;
    esac

    case "$proton_runtimes" in
        none|unknown|unavailable|"")
            printf '%s\n' "warning"
            ;;
        *)
            printf '%s\n' "healthy"
            ;;
    esac
}

get_gaming_diagnostics_summary_message() {
    local vulkan_status="$1"
    local steam_status="$2"
    local vulkan_32bit_status="$3"
    local proton_runtimes="$4"

    if [[ "$vulkan_status" != "available" ]]; then
        printf '%s\n' \
            "Vulkan could not be verified, so detailed gaming diagnostics are incomplete."
        return
    fi

    if ! gaming_diagnostics_steam_available "$steam_status"; then
        printf '%s\n' \
            "Steam is not available, so Steam and Proton diagnostics are incomplete."
        return
    fi

    case "$vulkan_32bit_status" in
        available|"managed by Flatpak")
            ;;
        *)
            printf '%s\n' \
                "Steam and Vulkan are available, but 32-bit Vulkan support could not be verified."
            return
            ;;
    esac

    case "$proton_runtimes" in
        none)
            printf '%s\n' \
                "Steam and Vulkan are available, but no installed Proton runtime was detected."
            ;;
        unknown|unavailable|"")
            printf '%s\n' \
                "Steam and Vulkan are available, but installed Proton runtimes could not be determined."
            ;;
        *)
            printf '%s\n' \
                "Steam, Vulkan, 32-bit graphics support and installed Proton runtimes were detected."
            ;;
    esac
}

print_gaming_diagnostics() {
    local vulkan_status
    local vulkan_instance_version
    local host_vulkan_32bit_status
    local vulkan_32bit_status
    local vulkan_devices
    local device_record
    local device_name
    local driver_name
    local api_version
    local steam_status
    local steam_launch_target
    local steam_libraries
    local steam_library
    local compatdata_count
    local proton_runtimes
    local proton_record
    local proton_type
    local proton_name
    local gamemode_status
    local mangohud_status
    local mangoapp_status
    local gamescope_status
    local gamescope_version
    local diagnostic_status
    local diagnostic_details

    vulkan_status="$(get_vulkan_status)"
    vulkan_instance_version="$(get_vulkan_instance_version)"
    host_vulkan_32bit_status="$(get_vulkan_32bit_loader_status)"
    vulkan_devices="$(get_vulkan_device_records)"

    steam_status="$(get_steam_status)"
    vulkan_32bit_status="$(
        get_effective_vulkan_32bit_status \
            "$steam_status" \
            "$host_vulkan_32bit_status"
    )"
    steam_launch_target="$(get_steam_launch_target)"
    steam_libraries="$(get_steam_library_roots)"
    compatdata_count="$(get_steam_compatdata_count)"
    proton_runtimes="$(get_installed_proton_runtimes)"

    gamemode_status="$(get_gaming_tool_status gamemoderun)"
    mangohud_status="$(get_gaming_tool_status mangohud)"
    mangoapp_status="$(get_gaming_tool_status mangoapp)"
    gamescope_status="$(get_gaming_tool_status gamescope)"
    gamescope_version="$(get_gamescope_version)"

    diagnostic_status="$(
        get_gaming_diagnostics_summary \
            "$vulkan_status" \
            "$steam_status" \
            "$vulkan_32bit_status" \
            "$proton_runtimes"
    )"

    diagnostic_details="$(
        get_gaming_diagnostics_summary_message \
            "$vulkan_status" \
            "$steam_status" \
            "$vulkan_32bit_status" \
            "$proton_runtimes"
    )"

    printf '%s\n' "Vulkan diagnostics:"
    printf '  Runtime:                 %s\n' "$vulkan_status"
    printf '  Instance version:        %s\n' "$vulkan_instance_version"
    printf '  32-bit Vulkan support:   %s\n' "$vulkan_32bit_status"
    printf '%s\n' "  Devices:"

    case "$vulkan_devices" in
        none|unknown|unavailable|"not verified"|"")
            printf '    %s\n' "${vulkan_devices:-unknown}"
            ;;
        *)
            while IFS= read -r device_record; do
                [[ -n "$device_record" ]] || continue

                device_name="$(
                    get_gaming_diagnostic_record_value \
                        "$device_record" \
                        device
                )"
                driver_name="$(
                    get_gaming_diagnostic_record_value \
                        "$device_record" \
                        driver
                )"
                api_version="$(
                    get_gaming_diagnostic_record_value \
                        "$device_record" \
                        api
                )"

                printf '    %s\n' "$device_name"
                printf '      Driver:              %s\n' "$driver_name"
                printf '      API version:         %s\n' "$api_version"
            done <<< "$vulkan_devices"
            ;;
    esac

    echo
    printf '%s\n' "Steam and Proton:"
    printf '  Steam:                   %s\n' "$steam_status"
    printf '  Launch target:           %s\n' "$steam_launch_target"
    printf '  Compatibility prefixes: %s\n' "$compatdata_count"
    printf '%s\n' "  Library roots:"

    case "$steam_libraries" in
        none|unknown|unavailable|"")
            printf '    %s\n' "${steam_libraries:-unknown}"
            ;;
        *)
            while IFS= read -r steam_library; do
                [[ -n "$steam_library" ]] || continue
                printf '    %s\n' "$steam_library"
            done <<< "$steam_libraries"
            ;;
    esac

    printf '%s\n' "  Proton runtimes:"

    case "$proton_runtimes" in
        none|unknown|unavailable|"")
            printf '    %s\n' "${proton_runtimes:-unknown}"
            ;;
        *)
            while IFS= read -r proton_record; do
                [[ -n "$proton_record" ]] || continue

                proton_type="${proton_record%%|*}"
                proton_name="${proton_record#*|}"

                if [[ "$proton_name" == "$proton_record" ]]; then
                    proton_type="unknown"
                    proton_name="$proton_record"
                fi

                printf '    %-10s %s\n' \
                    "${proton_type}:" \
                    "$proton_name"
            done <<< "$proton_runtimes"
            ;;
    esac

    echo
    printf '%s\n' "Gaming integrations:"
    printf '  GameMode:                %s\n' "$gamemode_status"
    printf '  MangoHud:                %s\n' "$mangohud_status"
    printf '  MangoApp:                %s\n' "$mangoapp_status"
    printf '  Gamescope:               %s\n' "$gamescope_status"
    printf '  Gamescope version:       %s\n' "$gamescope_version"

    echo
    printf '%s\n' "Overall diagnostics:"
    printf '  Status:                  %s\n' "$diagnostic_status"
    printf '  Details:                 %s\n' "$diagnostic_details"
}

show_gaming_diagnostics() {
    draw_module_header "Gaming Diagnostics"

    log_info "Reading detailed gaming diagnostics..."
    echo

    print_gaming_diagnostics

    echo
    read -rp "Press Enter to continue..."
}
