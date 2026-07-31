#!/usr/bin/env bash

print_network_information() {
    local network_interfaces
    local ipv4_addresses
    local default_gateway
    local dns_servers

    network_interfaces="$(get_active_network_interfaces)"
    ipv4_addresses="$(get_ipv4_addresses)"
    default_gateway="$(get_default_gateway)"
    dns_servers="$(get_dns_servers)"

    printf 'Interfaces:       %s\n' "$network_interfaces"
    printf 'IPv4 addresses:   %s\n' "$ipv4_addresses"
    printf 'Default gateway:  %s\n' "$default_gateway"
    printf 'DNS servers:      %s\n' "$dns_servers"
}

show_network_information() {
    draw_module_header "Network Information"

    log_debug "Network information collection started."
    log_info "Reading network information..."
    echo

    print_network_information

    echo
    read -rp "Press Enter to continue..."
}
