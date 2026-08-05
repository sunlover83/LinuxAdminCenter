#!/usr/bin/env bash

is_gaming_tool_available() {
    local tool_name="$1"
    local tool_path=""

    if ! tool_path="$(command -v "$tool_name" 2>/dev/null)"; then
        return 1
    fi

    [[ -n "$tool_path" && -x "$tool_path" ]]
}

get_gaming_tool_status() {
    local tool_name="$1"

    if is_gaming_tool_available "$tool_name"; then
        printf '%s\n' "available"
    else
        printf '%s\n' "not installed"
    fi
}

get_display_server() {
    local session_type="${XDG_SESSION_TYPE:-}"

    if [[ -n "$session_type" ]]; then
        printf '%s\n' "$session_type" |
            tr '[:upper:]' '[:lower:]'
        return
    fi

    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        printf '%s\n' "wayland"
    elif [[ -n "${DISPLAY:-}" ]]; then
        printf '%s\n' "x11"
    else
        printf '%s\n' "unknown"
    fi
}

get_desktop_environment() {
    local desktop_environment="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"

    if [[ -n "$desktop_environment" ]]; then
        printf '%s\n' "$desktop_environment"
    else
        printf '%s\n' "unknown"
    fi
}

get_graphics_drivers() {
    local drivers=""

    if ! is_gaming_tool_available lspci; then
        printf '%s\n' "unavailable"
        return
    fi

    drivers="$(
        LC_ALL=C lspci -k 2>/dev/null |
            awk '
                /(VGA compatible controller|3D controller|Display controller)/ {
                    graphics_device = 1
                    next
                }

                graphics_device &&
                /^[[:space:]]*Kernel driver in use:/ {
                    driver = $0
                    sub(/^[[:space:]]*Kernel driver in use:[[:space:]]*/, "", driver)

                    if (driver != "" && !seen[driver]++) {
                        print driver
                    }

                    graphics_device = 0
                    next
                }

                graphics_device && /^[^[:space:]]/ {
                    graphics_device = 0
                }
            ' |
            awk '
                BEGIN {
                    separator = ""
                }

                {
                    printf "%s%s", separator, $0
                    separator = ", "
                }

                END {
                    if (NR > 0) {
                        print ""
                    }
                }
            '
    )"

    if [[ -n "$drivers" ]]; then
        printf '%s\n' "$drivers"
    else
        printf '%s\n' "unknown"
    fi
}

get_nvidia_driver_version() {
    local driver_version=""

    if ! is_gaming_tool_available nvidia-smi; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! driver_version="$(
        LC_ALL=C nvidia-smi \
            --query-gpu=driver_version \
            --format=csv,noheader \
            2>/dev/null |
            awk 'NF > 0 && !seen[$0]++ { print; exit }'
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    if [[ -n "$driver_version" ]]; then
        printf '%s\n' "$driver_version"
    else
        printf '%s\n' "unknown"
    fi
}

get_vulkan_status() {
    if ! is_gaming_tool_available vulkaninfo; then
        printf '%s\n' "not verified"
        return
    fi

    if LC_ALL=C vulkaninfo --summary >/dev/null 2>&1; then
        printf '%s\n' "available"
    else
        printf '%s\n' "unavailable"
    fi
}

get_steam_status() {
    if is_gaming_tool_available steam; then
        printf '%s\n' "available (native)"
        return
    fi

    if is_gaming_tool_available flatpak &&
        flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
        printf '%s\n' "available (flatpak)"
        return
    fi

    printf '%s\n' "not installed"
}

get_proton_compatibility_tools() {
    local home_directory="${LAC_HOME_DIR:-${HOME:-}}"
    local compatibility_directory
    local tool_name
    local tool_names=""
    local -a compatibility_directories=()

    if [[ -z "$home_directory" ]]; then
        printf '%s\n' "unknown"
        return
    fi

    compatibility_directories=(
        "${home_directory}/.steam/root/compatibilitytools.d"
        "${home_directory}/.local/share/Steam/compatibilitytools.d"
        "${home_directory}/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d"
    )

    for compatibility_directory in "${compatibility_directories[@]}"; do
        [[ -d "$compatibility_directory" ]] || continue

        while IFS= read -r tool_name; do
            [[ -n "$tool_name" ]] || continue
            tool_names+="${tool_name}"$'\n'
        done < <(
            find "$compatibility_directory" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -printf '%f\n' \
                2>/dev/null
        )
    done

    if [[ -n "$tool_names" ]]; then
        printf '%s' "$tool_names" |
            sort -u
    else
        printf '%s\n' "none"
    fi
}
