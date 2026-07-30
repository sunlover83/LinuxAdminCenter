#!/usr/bin/env bash

get_system_hostname() {
    local hostname_value

    if hostname_value="$(hostname 2>/dev/null)"; then
        printf '%s\n' "$hostname_value"
    elif [[ -r /etc/hostname ]]; then
        cat /etc/hostname
    else
        printf '%s\n' "unknown"
    fi
}

get_kernel_version() {
    uname -r 2>/dev/null || printf '%s\n' "unknown"
}

get_system_architecture() {
    uname -m 2>/dev/null || printf '%s\n' "unknown"
}

get_system_uptime() {
    local uptime_value
    local total_seconds
    local days
    local hours
    local minutes

    if [[ ! -r /proc/uptime ]]; then
        printf '%s\n' "unknown"
        return
    fi

    read -r uptime_value _ < /proc/uptime
    total_seconds="${uptime_value%%.*}"

    days=$((total_seconds / 86400))
    hours=$(((total_seconds % 86400) / 3600))
    minutes=$(((total_seconds % 3600) / 60))

    printf '%sd %sh %sm\n' \
        "$days" \
        "$hours" \
        "$minutes"
}

print_system_information() {
    local hostname_value
    local kernel_version
    local architecture
    local uptime_value

    hostname_value="$(get_system_hostname)"
    kernel_version="$(get_kernel_version)"
    architecture="$(get_system_architecture)"
    uptime_value="$(get_system_uptime)"

    printf 'Distribution:     %s\n' "$DISTRO_NAME"
    printf 'Distribution ID:  %s\n' "$DISTRO_ID"
    printf 'Version:          %s\n' "$DISTRO_VERSION"
    printf 'Package manager:  %s\n' "$PKG_MANAGER"
    printf 'Hostname:         %s\n' "$hostname_value"
    printf 'Kernel:           %s\n' "$kernel_version"
    printf 'Architecture:     %s\n' "$architecture"
    printf 'Uptime:           %s\n' "$uptime_value"
}

print_reboot_status() {
    if is_reboot_required; then
        printf '%s\n' "Restart required: Yes"
    else
        printf '%s\n' "Restart required: No"
    fi
}

show_system_information() {
    detect_distribution
    draw_module_header "System Information"

    log_debug "Distribution detection completed."
    log_info "Reading system information..."
    echo

    print_system_information
    echo

    if is_reboot_required; then
        log_warning "A system restart is required."
    else
        log_success "No system restart is required."
    fi

    echo
    read -rp "Press Enter to continue..."
}
