#!/usr/bin/env bash

get_ping_connectivity_status() {
    local diagnostic_result="$1"

    case "$diagnostic_result" in
        reachable\|*)
            printf '%s\n' "reachable"
            ;;
        unreachable\|*)
            printf '%s\n' "unreachable"
            ;;
        *)
            printf '%s\n' "$diagnostic_result"
            ;;
    esac
}

format_ping_diagnostics() {
    local diagnostic_result="$1"
    local connectivity_status
    local packet_loss
    local average_latency

    case "$diagnostic_result" in
        reachable\|*|unreachable\|*)
            IFS='|' read -r \
                connectivity_status \
                packet_loss \
                average_latency <<< "$diagnostic_result"

            packet_loss="${packet_loss#packet_loss=}"
            average_latency="${average_latency#average_latency=}"

            printf '%s | packet loss: %s | average latency: %s\n' \
                "$connectivity_status" \
                "$packet_loss" \
                "$average_latency"
            ;;
        *)
            printf '%s\n' "$diagnostic_result"
            ;;
    esac
}

get_network_diagnostic_summary() {
    local default_gateway="$1"
    local gateway_connectivity="$2"
    local dns_resolution="$3"
    local internet_connectivity="$4"
    local gateway_status
    local internet_status

    gateway_status="$(
        get_ping_connectivity_status "$gateway_connectivity"
    )"

    internet_status="$(
        get_ping_connectivity_status "$internet_connectivity"
    )"

    if [[ "$default_gateway" == "none" ]]; then
        printf '%s\n' "failed"
        return
    fi

    if [[ "$dns_resolution" == "failed" ]] &&
        [[ "$internet_status" != "reachable" ]]; then
        printf '%s\n' "failed"
        return
    fi

    if [[ "$gateway_status" == "reachable" ]] &&
        [[ "$dns_resolution" == "working" ]] &&
        [[ "$internet_status" == "reachable" ]]; then
        printf '%s\n' "healthy"
        return
    fi

    printf '%s\n' "warning"
}

get_network_diagnostic_summary_message() {
    local default_gateway="$1"
    local gateway_connectivity="$2"
    local dns_resolution="$3"
    local internet_connectivity="$4"
    local gateway_status
    local internet_status
    local overall_status

    gateway_status="$(
        get_ping_connectivity_status "$gateway_connectivity"
    )"

    internet_status="$(
        get_ping_connectivity_status "$internet_connectivity"
    )"

    overall_status="$(
        get_network_diagnostic_summary \
            "$default_gateway" \
            "$gateway_connectivity" \
            "$dns_resolution" \
            "$internet_connectivity"
    )"

    if [[ "$overall_status" == "healthy" ]]; then
        printf '%s\n' "All connectivity checks passed."
        return
    fi

    if [[ "$default_gateway" == "none" ]]; then
        printf '%s\n' "No IPv4 default gateway is configured."
        return
    fi

    if [[ "$dns_resolution" == "failed" ]] &&
        [[ "$internet_status" != "reachable" ]]; then
        printf '%s\n' \
            "DNS resolution and external reachability checks failed."
        return
    fi

    if [[ "$gateway_status" == "unreachable" ]] &&
        [[ "$internet_status" == "reachable" ]]; then
        printf '%s\n' \
            "The gateway did not answer ICMP, but external connectivity is working."
        return
    fi

    if [[ "$dns_resolution" == "working" ]] &&
        [[ "$internet_status" == "unreachable" ]]; then
        printf '%s\n' \
            "DNS resolution works, but the external ping target did not respond; ICMP may be blocked."
        return
    fi

    if [[ "$dns_resolution" == "failed" ]] &&
        [[ "$internet_status" == "reachable" ]]; then
        printf '%s\n' \
            "External connectivity works by IP, but DNS resolution failed."
        return
    fi

    if [[ "$gateway_status" == "unavailable" ]] ||
        [[ "$internet_status" == "unavailable" ]]; then
        printf '%s\n' \
            "Ping is unavailable, so reachability checks are incomplete."
        return
    fi

    if [[ "$default_gateway" == "unavailable" ]] ||
        [[ "$default_gateway" == "unknown" ]]; then
        printf '%s\n' \
            "The default gateway could not be determined."
        return
    fi

    if [[ "$gateway_status" == "unreachable" ]] &&
        [[ "$internet_status" == "unreachable" ]]; then
        printf '%s\n' \
            "Gateway and external ping targets did not respond; connectivity may be degraded or ICMP may be blocked."
        return
    fi

    printf '%s\n' \
        "One or more connectivity checks could not be completed."
}

print_network_diagnostics() {
    local ip_status
    local ping_status
    local getent_status
    local default_gateway
    local gateway_connectivity
    local dns_test_host
    local dns_resolution
    local internet_test_target
    local internet_connectivity
    local overall_status
    local overall_details

    ip_status="$(get_network_diagnostic_tool_status ip)"
    ping_status="$(get_network_diagnostic_tool_status ping)"
    getent_status="$(get_network_diagnostic_tool_status getent)"

    default_gateway="$(get_default_gateway_address)"
    gateway_connectivity="$(get_gateway_connectivity)"

    dns_test_host="${LAC_DNS_TEST_HOST:-example.com}"
    dns_resolution="$(get_dns_resolution_status "$dns_test_host")"

    internet_test_target="${LAC_INTERNET_TEST_TARGET:-1.1.1.1}"
    internet_connectivity="$(get_internet_connectivity)"

    overall_status="$(
        get_network_diagnostic_summary \
            "$default_gateway" \
            "$gateway_connectivity" \
            "$dns_resolution" \
            "$internet_connectivity"
    )"

    overall_details="$(
        get_network_diagnostic_summary_message \
            "$default_gateway" \
            "$gateway_connectivity" \
            "$dns_resolution" \
            "$internet_connectivity"
    )"

    printf '%s\n' "Diagnostic tools:"
    printf '  ip:            %s\n' "$ip_status"
    printf '  ping:          %s\n' "$ping_status"
    printf '  getent:        %s\n' "$getent_status"
    echo

    printf '%s\n' "Network connectivity:"
    printf '  Default gateway:  %s\n' "$default_gateway"

    printf '  Gateway test:     '
    format_ping_diagnostics "$gateway_connectivity"

    printf '  DNS resolution:   %s (%s)\n' \
        "$dns_resolution" \
        "$dns_test_host"

    printf '  Internet test:    '
    format_ping_diagnostics "$internet_connectivity"

    printf '  Internet target:  %s\n' \
        "$internet_test_target"

    echo
    printf '%s\n' "Overall assessment:"
    printf '  Status:   %s\n' "$overall_status"
    printf '  Details:  %s\n' "$overall_details"
}

show_network_diagnostics() {
    draw_module_header "Network Diagnostics"

    log_info "Running read-only network diagnostics..."
    echo

    print_network_diagnostics

    echo
    read -rp "Press Enter to continue..."
}
