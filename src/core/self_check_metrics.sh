#!/usr/bin/env bash

get_bash_runtime_status() {
    if is_current_bash_version_supported; then
        printf 'compatible (%s)\n' "$BASH_VERSION"
    else
        printf 'unsupported (%s)\n' "$BASH_VERSION"
    fi
}

get_lac_runtime_root() {
    printf '%s\n' "${SCRIPT_DIR:-unknown}"
}

get_lac_installation_type() {
    local runtime_root="${1:-$(get_lac_runtime_root)}"

    case "$runtime_root" in
        */lib/linux-admin-center)
            printf '%s\n' "system-wide"
            ;;
        */src)
            printf '%s\n' "repository"
            ;;
        unknown|"")
            printf '%s\n' "unknown"
            ;;
        *)
            printf '%s\n' "custom"
            ;;
    esac
}

get_lac_runtime_file_records() {
    local runtime_root="${1:-$(get_lac_runtime_root)}"
    local relative_path
    local -a required_files=(
        "lac.sh"
        "core/common.sh"
        "core/config.sh"
        "core/system_metrics.sh"
        "core/network_metrics.sh"
        "core/network_diagnostics_metrics.sh"
        "core/cleanup_metrics.sh"
        "core/hardware_metrics.sh"
        "core/gaming_metrics.sh"
        "core/gaming_diagnostics_metrics.sh"
        "core/service_metrics.sh"
        "core/self_check_metrics.sh"
        "core/cli.sh"
        "core/package_manager.sh"
        "core/ui.sh"
        "modules/update/update.sh"
        "modules/cleanup/cleanup.sh"
        "modules/network_info/network_info.sh"
        "modules/system_info/system_info.sh"
        "modules/hardware_diagnostics/hardware_diagnostics.sh"
        "modules/network_diagnostics/network_diagnostics.sh"
        "modules/gaming_readiness/gaming_readiness.sh"
        "modules/gaming_diagnostics/gaming_diagnostics.sh"
        "modules/service_health/service_health.sh"
        "modules/self_check/self_check.sh"
    )

    for relative_path in "${required_files[@]}"; do
        if [[ -r "${runtime_root}/${relative_path}" ]]; then
            printf '%s|available\n' "$relative_path"
        else
            printf '%s|missing\n' "$relative_path"
        fi
    done
}

get_lac_runtime_files_status() {
    local runtime_root="${1:-$(get_lac_runtime_root)}"
    local records
    local missing_count

    records="$(get_lac_runtime_file_records "$runtime_root")"
    missing_count="$(awk -F '|' '$2 == "missing" { count++ } END { print count + 0 }' <<< "$records")"

    if (( missing_count == 0 )); then
        printf '%s\n' "complete"
    else
        printf 'missing (%s)\n' "$missing_count"
    fi
}

get_lac_launcher_status() {
    local runtime_root="${1:-$(get_lac_runtime_root)}"
    local installation_type
    local prefix

    installation_type="$(get_lac_installation_type "$runtime_root")"

    if [[ "$installation_type" != "system-wide" ]]; then
        printf '%s\n' "not applicable"
        return
    fi

    prefix="${runtime_root%/lib/linux-admin-center}"

    if [[ -x "${prefix}/bin/lac" && -x "${prefix}/bin/lac-uninstall" ]]; then
        printf '%s\n' "available"
    else
        printf '%s\n' "incomplete"
    fi
}

get_lac_config_file_status() {
    local config_file="$1"

    if [[ -z "$config_file" ]]; then
        printf '%s\n' "defaults"
    elif [[ -e "$config_file" ]]; then
        if [[ -r "$config_file" ]]; then
            printf '%s\n' "available"
        else
            printf '%s\n' "not readable"
        fi
    else
        printf '%s\n' "defaults"
    fi
}

get_lac_system_config_status() {
    local config_file="${LAC_SYSTEM_CONFIG:-/etc/lac/lac.conf}"

    get_lac_config_file_status "$config_file"
}

get_lac_user_config_status() {
    local config_file

    config_file="$(get_lac_user_config_path)"
    get_lac_config_file_status "$config_file"
}

get_lac_required_tool_records() {
    local tool
    local -a required_tools=(
        awk
        sed
        find
        sort
        tr
        uname
        df
        du
        hostname
    )

    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf '%s|available\n' "$tool"
        else
            printf '%s|missing\n' "$tool"
        fi
    done
}

get_lac_required_tools_status() {
    local records
    local missing_count

    records="$(get_lac_required_tool_records)"
    missing_count="$(awk -F '|' '$2 == "missing" { count++ } END { print count + 0 }' <<< "$records")"

    if (( missing_count == 0 )); then
        printf '%s\n' "complete"
    else
        printf 'missing (%s)\n' "$missing_count"
    fi
}

get_lac_optional_tool_records() {
    local tool
    local -a optional_tools=(
        ip
        ping
        getent
        lscpu
        lspci
        lsblk
        sensors
        nvidia-smi
        smartctl
        nvme
        resolvectl
        journalctl
        vulkaninfo
        steam
        flatpak
        gamemoderun
        mangohud
        mangoapp
        gamescope
        ps
        systemctl
        systemd-analyze
        checkupdates
        paccache
    )

    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            printf '%s|available\n' "$tool"
        else
            printf '%s|not installed\n' "$tool"
        fi
    done
}

get_lac_package_manager_status() {
    detect_distribution

    if is_package_manager_supported; then
        printf '%s|available\n' "$PKG_MANAGER"
    else
        printf '%s|unavailable\n' "$PKG_MANAGER"
    fi
}
