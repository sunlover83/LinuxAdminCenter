#!/usr/bin/env bash

is_network_diagnostic_tool_available() {
    local tool_name="$1"

    command -v "$tool_name" >/dev/null 2>&1
}

get_network_diagnostic_tool_status() {
    local tool_name="$1"

    if is_network_diagnostic_tool_available "$tool_name"; then
        printf '%s\n' "available"
    else
        printf '%s\n' "not installed"
    fi
}

is_safe_network_target() {
    local target="${1:-}"

    [[ -n "$target" ]] || return 1
    [[ "$target" != -* ]] || return 1
    [[ "$target" != *[[:space:]]* ]] || return 1

    return 0
}

get_default_gateway_address() {
    local gateway=""

    if ! is_network_diagnostic_tool_available ip; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! gateway="$(
        LC_ALL=C ip -4 route show default 2>/dev/null |
            awk '
                /^default/ {
                    for (i = 1; i <= NF; i++) {
                        if ($i == "via" && i < NF) {
                            print $(i + 1)
                            exit
                        }
                    }
                }
            '
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    if [[ -n "$gateway" ]]; then
        printf '%s\n' "$gateway"
    else
        printf '%s\n' "none"
    fi
}

get_ping_diagnostics() {
    local target="${1:-}"
    local packet_count="${2:-3}"
    local timeout_seconds="${3:-2}"
    local ping_output=""
    local ping_status=0
    local packet_loss=""
    local average_latency=""

    if ! is_safe_network_target "$target"; then
        printf '%s\n' "invalid target"
        return
    fi

    if ! is_network_diagnostic_tool_available ping; then
        printf '%s\n' "unavailable"
        return
    fi

    ping_output="$(
        LC_ALL=C ping \
            -n \
            -c "$packet_count" \
            -W "$timeout_seconds" \
            "$target" \
            2>&1
    )" || ping_status=$?

    packet_loss="$(
        awk '
            match($0, /[0-9]+([.][0-9]+)?% packet loss/) {
                value = substr($0, RSTART, RLENGTH)
                sub(/% packet loss$/, "", value)
                print value
                exit
            }
        ' <<< "$ping_output"
    )"

    average_latency="$(
        awk -F '=' '
            /^(rtt|round-trip) / {
                values = $2
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", values)
                split(values, parts, "/")

                if (parts[2] != "") {
                    print parts[2]
                }

                exit
            }
        ' <<< "$ping_output"
    )"

    if [[ "$average_latency" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        average_latency="$(
            LC_NUMERIC=C printf '%.1f' "$average_latency"
        ) ms"
    else
        average_latency="unknown"
    fi

    if [[ "$packet_loss" =~ ^100([.]0+)?$ ]]; then
        printf 'unreachable|packet_loss=%s%%|average_latency=%s\n' \
            "$packet_loss" \
            "$average_latency"
    elif [[ -n "$packet_loss" ]]; then
        printf 'reachable|packet_loss=%s%%|average_latency=%s\n' \
            "$packet_loss" \
            "$average_latency"
    elif (( ping_status == 0 )); then
        printf 'reachable|packet_loss=unknown|average_latency=%s\n' \
            "$average_latency"
    else
        printf '%s\n' "unknown"
    fi
}

get_gateway_connectivity() {
    local gateway

    gateway="$(get_default_gateway_address)"

    case "$gateway" in
        unavailable|unknown)
            printf '%s\n' "$gateway"
            ;;
        none)
            printf '%s\n' "no gateway"
            ;;
        *)
            get_ping_diagnostics "$gateway"
            ;;
    esac
}

get_dns_resolution_status() {
    local hostname="${1:-${LAC_DNS_TEST_HOST:-example.com}}"

    if ! is_safe_network_target "$hostname"; then
        printf '%s\n' "invalid target"
        return
    fi

    if ! is_network_diagnostic_tool_available getent; then
        printf '%s\n' "unavailable"
        return
    fi

    if LC_ALL=C getent ahosts "$hostname" 2>/dev/null |
        awk 'NF > 0 { found = 1 } END { exit !found }'; then
        printf '%s\n' "working"
    else
        printf '%s\n' "failed"
    fi
}

get_internet_connectivity() {
    local target="${LAC_INTERNET_TEST_TARGET:-1.1.1.1}"

    get_ping_diagnostics "$target"
}
