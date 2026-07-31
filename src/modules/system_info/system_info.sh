#!/usr/bin/env bash

print_system_information() {
    local hostname_value
    local kernel_version
    local architecture
    local cpu_model
    local logical_cpu_count
    local gpu_models
    local uptime_value
    local memory_usage
    local root_disk_usage
    local load_average
    local network_interfaces
    local ipv4_addresses
    local default_gateway
    local dns_servers

    hostname_value="$(get_system_hostname)"
    kernel_version="$(get_kernel_version)"
    architecture="$(get_system_architecture)"
    cpu_model="$(get_cpu_model)"
    logical_cpu_count="$(get_logical_cpu_count)"
    gpu_models="$(get_gpu_models)"
    uptime_value="$(get_system_uptime)"
    memory_usage="$(get_memory_usage)"
    root_disk_usage="$(get_root_disk_usage)"
    load_average="$(get_load_average)"
    network_interfaces="$(get_active_network_interfaces)"
    ipv4_addresses="$(get_ipv4_addresses)"
    default_gateway="$(get_default_gateway)"
    dns_servers="$(get_dns_servers)"

    printf 'Distribution:     %s\n' "$DISTRO_NAME"
    printf 'Distribution ID:  %s\n' "$DISTRO_ID"
    printf 'Version:          %s\n' "$DISTRO_VERSION"
    printf 'Package manager:  %s\n' "$PKG_MANAGER"
    printf 'Hostname:         %s\n' "$hostname_value"
    printf 'Kernel:           %s\n' "$kernel_version"
    printf 'Architecture:     %s\n' "$architecture"
    printf 'CPU:              %s\n' "$cpu_model"
    printf 'Logical CPUs:     %s\n' "$logical_cpu_count"
    printf 'GPU:              %s\n' "$gpu_models"
    printf 'Uptime:           %s\n' "$uptime_value"
    printf 'Memory:           %s\n' "$memory_usage"
    printf 'Root disk:        %s\n' "$root_disk_usage"
    printf 'Load average:     %s\n' "$load_average"
    printf 'Interfaces:       %s\n' "$network_interfaces"
    printf 'IPv4 addresses:   %s\n' "$ipv4_addresses"
    printf 'Default gateway:  %s\n' "$default_gateway"
    printf 'DNS servers:      %s\n' "$dns_servers"
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
