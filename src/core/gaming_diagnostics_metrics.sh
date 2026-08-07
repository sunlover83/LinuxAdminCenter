#!/usr/bin/env bash

get_vulkan_instance_version() {
    local summary_output=""
    local instance_version=""

    if ! is_gaming_tool_available vulkaninfo; then
        printf '%s\n' "not verified"
        return
    fi

    if ! summary_output="$(
        LC_ALL=C vulkaninfo --summary 2>/dev/null
    )"; then
        printf '%s\n' "unavailable"
        return
    fi

    instance_version="$(
        awk -F ':' '
            /^[[:space:]]*Vulkan Instance Version:/ {
                value = $2
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                print value
                exit
            }
        ' <<< "$summary_output"
    )"

    if [[ -n "$instance_version" ]]; then
        printf '%s\n' "$instance_version"
    else
        printf '%s\n' "unknown"
    fi
}

get_vulkan_device_records() {
    local summary_output=""
    local device_records=""

    if ! is_gaming_tool_available vulkaninfo; then
        printf '%s\n' "not verified"
        return
    fi

    if ! summary_output="$(
        LC_ALL=C vulkaninfo --summary 2>/dev/null
    )"; then
        printf '%s\n' "unavailable"
        return
    fi

    device_records="$(
        awk '
            function clean(value) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                gsub(/[|]/, "/", value)
                return value
            }

            function emit_device() {
                if (device_name == "") {
                    return
                }

                printf \
                    "device=%s|driver=%s|api=%s\n", \
                    clean(device_name), \
                    clean(driver_name), \
                    clean(api_version)
            }

            /^GPU[0-9]+:/ {
                emit_device()
                in_gpu = 1
                device_name = ""
                driver_name = ""
                api_version = ""
                next
            }

            in_gpu && /^[[:space:]]*deviceName[[:space:]]*=/ {
                value = $0
                sub(/^[^=]*=[[:space:]]*/, "", value)
                device_name = value
                next
            }

            in_gpu && /^[[:space:]]*driverName[[:space:]]*=/ {
                value = $0
                sub(/^[^=]*=[[:space:]]*/, "", value)
                driver_name = value
                next
            }

            in_gpu && /^[[:space:]]*apiVersion[[:space:]]*=/ {
                value = $0
                sub(/^[^=]*=[[:space:]]*/, "", value)
                api_version = value
                next
            }

            END {
                emit_device()
            }
        ' <<< "$summary_output"
    )"

    if [[ -n "$device_records" ]]; then
        printf '%s\n' "$device_records"
    else
        printf '%s\n' "none"
    fi
}

get_vulkan_32bit_loader_status() {
    local root_directory="${LAC_ROOT_DIR:-}"
    local library_path
    local -a library_paths=(
        "/usr/lib32/libvulkan.so.1"
        "/usr/lib/i386-linux-gnu/libvulkan.so.1"
        "/lib/i386-linux-gnu/libvulkan.so.1"
        "/usr/lib/libvulkan.so.1"
    )

    for library_path in "${library_paths[@]}"; do
        if [[ -e "${root_directory}${library_path}" ]]; then
            printf '%s\n' "available"
            return
        fi
    done

    printf '%s\n' "not verified"
}

get_steam_launch_target() {
    local steam_path=""

    if steam_path="$(command -v steam 2>/dev/null)" &&
        [[ -n "$steam_path" && -x "$steam_path" ]]; then
        printf '%s\n' "$steam_path"
        return
    fi

    if is_gaming_tool_available flatpak &&
        flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
        printf '%s\n' "flatpak:com.valvesoftware.Steam"
        return
    fi

    printf '%s\n' "unavailable"
}

get_steam_library_roots() {
    local home_directory="${LAC_HOME_DIR:-${HOME:-}}"
    local steam_root
    local resolved_root
    local library_config
    local library_root
    local resolved_library_root
    local roots=""
    local -a steam_roots=()

    if [[ -z "$home_directory" ]]; then
        printf '%s\n' "unknown"
        return
    fi

    steam_roots=(
        "${home_directory}/.steam/root"
        "${home_directory}/.local/share/Steam"
        "${home_directory}/.var/app/com.valvesoftware.Steam/data/Steam"
    )

    for steam_root in "${steam_roots[@]}"; do
        [[ -d "$steam_root" ]] || continue

        resolved_root="$(
            cd "$steam_root" 2>/dev/null && pwd -P
        )" || resolved_root="$steam_root"

        roots+="${resolved_root}"$'\n'

        library_config="${steam_root}/steamapps/libraryfolders.vdf"
        [[ -r "$library_config" ]] || continue

        while IFS= read -r library_root; do
            [[ -n "$library_root" && -d "$library_root" ]] || continue

            resolved_library_root="$(
                cd "$library_root" 2>/dev/null && pwd -P
            )" || resolved_library_root="$library_root"

            roots+="${resolved_library_root}"$'\n'
        done < <(
            awk -F '"' '
                $2 == "path" && $4 != "" {
                    print $4
                }
            ' "$library_config" 2>/dev/null
        )
    done

    if [[ -n "$roots" ]]; then
        printf '%s' "$roots" |
            awk 'NF && !seen[$0]++' |
            LC_ALL=C sort
    else
        printf '%s\n' "none"
    fi
}

get_installed_proton_runtimes() {
    local library_roots
    local library_root
    local proton_directory
    local proton_tools
    local proton_tool
    local runtimes=""

    library_roots="$(get_steam_library_roots)"

    case "$library_roots" in
        unknown)
            printf '%s\n' "unknown"
            return
            ;;
        none)
            ;;
        *)
            while IFS= read -r library_root; do
                [[ -n "$library_root" ]] || continue
                [[ -d "${library_root}/steamapps/common" ]] || continue

                while IFS= read -r proton_directory; do
                    [[ -n "$proton_directory" ]] || continue
                    [[ -f "${proton_directory}/proton" ]] || continue

                    runtimes+="bundled|${proton_directory##*/}"$'\n'
                done < <(
                    find "${library_root}/steamapps/common" \
                        -mindepth 1 \
                        -maxdepth 1 \
                        -type d \
                        -name 'Proton*' \
                        -print \
                        2>/dev/null
                )
            done <<< "$library_roots"
            ;;
    esac

    proton_tools="$(get_proton_compatibility_tools)"

    case "$proton_tools" in
        unknown)
            if [[ -z "$runtimes" ]]; then
                printf '%s\n' "unknown"
                return
            fi
            ;;
        none)
            ;;
        *)
            while IFS= read -r proton_tool; do
                [[ -n "$proton_tool" ]] || continue
                runtimes+="custom|${proton_tool}"$'\n'
            done <<< "$proton_tools"
            ;;
    esac

    if [[ -n "$runtimes" ]]; then
        printf '%s' "$runtimes" |
            sort -u
    else
        printf '%s\n' "none"
    fi
}

get_steam_compatdata_count() {
    local library_roots
    local library_root
    local app_id
    local -A seen_app_ids=()

    library_roots="$(get_steam_library_roots)"

    case "$library_roots" in
        unknown)
            printf '%s\n' "unknown"
            return
            ;;
        none)
            printf '%s\n' "0"
            return
            ;;
    esac

    while IFS= read -r library_root; do
        [[ -n "$library_root" ]] || continue
        [[ -d "${library_root}/steamapps/compatdata" ]] || continue

        while IFS= read -r app_id; do
            [[ "$app_id" =~ ^[0-9]+$ ]] || continue
            seen_app_ids["$app_id"]=1
        done < <(
            find "${library_root}/steamapps/compatdata" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -printf '%f\n' \
                2>/dev/null
        )
    done <<< "$library_roots"

    printf '%s\n' "${#seen_app_ids[@]}"
}

get_gamescope_version() {
    local version_output=""
    local version_line=""

    if ! is_gaming_tool_available gamescope; then
        printf '%s\n' "not installed"
        return
    fi

    if ! version_output="$(
        LC_ALL=C gamescope --version 2>&1
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    version_line="$(
        awk '
            NF {
                line = $0
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                print line
                exit
            }
        ' <<< "$version_output"
    )"

    if [[ -n "$version_line" ]]; then
        printf '%s\n' "$version_line"
    else
        printf '%s\n' "unknown"
    fi
}
