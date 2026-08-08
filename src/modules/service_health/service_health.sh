#!/usr/bin/env bash

get_service_record_value() {
    local record="$1"
    local key="$2"
    local field
    local -a fields=()

    case "$record" in
        unsupported|unavailable|unknown|"invalid service")
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

get_service_health_summary() {
    local init_system="$1"
    local system_state="$2"
    local failed_service_count="$3"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' "failed"
        return
    fi

    case "$system_state" in
        maintenance|offline|stopping)
            printf '%s\n' "failed"
            return
            ;;
        unsupported|unavailable|unknown|"")
            printf '%s\n' "failed"
            return
            ;;
    esac

    if [[ ! "$failed_service_count" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "failed"
        return
    fi

    if (( failed_service_count > 0 )); then
        printf '%s\n' "warning"
        return
    fi

    case "$system_state" in
        running)
            printf '%s\n' "healthy"
            ;;
        initializing|starting|degraded)
            printf '%s\n' "warning"
            ;;
        *)
            printf '%s\n' "failed"
            ;;
    esac
}

get_service_health_summary_message() {
    local init_system="$1"
    local system_state="$2"
    local failed_service_count="$3"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' \
            "Service Health currently supports systemd systems only."
        return
    fi

    case "$system_state" in
        maintenance)
            printf '%s\n' "Systemd is in maintenance mode."
            return
            ;;
        offline)
            printf '%s\n' "Systemd reports the system as offline."
            return
            ;;
        stopping)
            printf '%s\n' "Systemd is stopping."
            return
            ;;
        unavailable)
            printf '%s\n' \
                "Systemctl is not available, so service health could not be evaluated."
            return
            ;;
        unsupported|unknown|"")
            printf '%s\n' \
                "The systemd system state could not be determined."
            return
            ;;
    esac

    if [[ ! "$failed_service_count" =~ ^[0-9]+$ ]]; then
        printf '%s\n' \
            "The number of failed systemd services could not be determined."
        return
    fi

    if (( failed_service_count == 1 )); then
        printf '%s\n' "One failed systemd service was detected."
        return
    fi

    if (( failed_service_count > 1 )); then
        printf '%s\n' \
            "${failed_service_count} failed systemd services were detected."
        return
    fi

    case "$system_state" in
        running)
            printf '%s\n' \
                "Systemd is running and no failed services were detected."
            ;;
        initializing)
            printf '%s\n' \
                "Systemd is still initializing."
            ;;
        starting)
            printf '%s\n' \
                "Systemd is still starting services."
            ;;
        degraded)
            printf '%s\n' \
                "Systemd reports a degraded state, although no failed services were listed."
            ;;
        *)
            printf '%s\n' \
                "Service health could not be evaluated completely."
            ;;
    esac
}

print_failed_service_details() {
    local failed_services="$1"
    local service_name
    local service_details
    local unit_name
    local description
    local load_state
    local active_state
    local sub_state

    printf '%s\n' "Failed service details:"

    case "$failed_services" in
        none)
            printf '%s\n' "  none"
            return
            ;;
        unsupported|unavailable|unknown|"")
            printf '  %s\n' "${failed_services:-unknown}"
            return
            ;;
    esac

    while IFS= read -r service_name; do
        [[ -n "$service_name" ]] || continue

        service_details="$(
            get_systemd_failed_service_details "$service_name"
        )"

        printf '  %s\n' "$service_name"

        case "$service_details" in
            unsupported|unavailable|unknown|"invalid service")
                printf '    Details:               %s\n' \
                    "$service_details"
                ;;
            *)
                unit_name="$(
                    get_service_record_value "$service_details" unit
                )"
                description="$(
                    get_service_record_value \
                        "$service_details" \
                        description
                )"
                load_state="$(
                    get_service_record_value "$service_details" load
                )"
                active_state="$(
                    get_service_record_value "$service_details" active
                )"
                sub_state="$(
                    get_service_record_value "$service_details" sub
                )"

                printf '    Unit:                  %s\n' "$unit_name"
                printf '    Description:           %s\n' "$description"
                printf '    Load state:            %s\n' "$load_state"
                printf '    Active state:          %s\n' "$active_state"
                printf '    Sub state:             %s\n' "$sub_state"
                ;;
        esac
    done <<< "$failed_services"
}

print_service_health() {
    local init_system
    local systemctl_status
    local systemd_analyze_status
    local system_state
    local service_counts
    local active_service_count
    local inactive_service_count
    local failed_service_count
    local failed_services
    local boot_time
    local slowest_services
    local health_status
    local health_details
    local service_record
    local service_name
    local duration

    init_system="$(get_init_system)"
    systemctl_status="$(get_service_tool_status systemctl)"
    systemd_analyze_status="$(
        get_service_tool_status systemd-analyze
    )"

    system_state="$(get_systemd_system_state)"
    service_counts="$(get_systemd_service_counts)"
    failed_service_count="$(get_failed_systemd_service_count)"
    failed_services="$(get_failed_systemd_services)"

    active_service_count="$(
        get_service_record_value "$service_counts" active
    )"
    inactive_service_count="$(
        get_service_record_value "$service_counts" inactive
    )"

    boot_time="$(get_systemd_boot_time)"
    slowest_services="$(get_slowest_systemd_services 5)"

    health_status="$(
        get_service_health_summary \
            "$init_system" \
            "$system_state" \
            "$failed_service_count"
    )"

    health_details="$(
        get_service_health_summary_message \
            "$init_system" \
            "$system_state" \
            "$failed_service_count"
    )"

    printf '%s\n' "Service environment:"
    printf '  Init system:             %s\n' "$init_system"
    printf '  systemctl:               %s\n' "$systemctl_status"
    printf '  systemd-analyze:         %s\n' \
        "$systemd_analyze_status"

    echo
    printf '%s\n' "Service status:"
    printf '  System state:            %s\n' "$system_state"
    printf '  Active services:         %s\n' \
        "$active_service_count"
    printf '  Inactive services:       %s\n' \
        "$inactive_service_count"
    printf '  Failed services:         %s\n' \
        "$failed_service_count"

    echo
    print_failed_service_details "$failed_services"

    echo
    printf '%s\n' "Boot performance:"
    printf '  Total boot time:         %s\n' "$boot_time"

    case "$slowest_services" in
        unsupported|unavailable|unknown|none|"")
            printf '  Slowest services:        %s\n' \
                "${slowest_services:-unknown}"
            ;;
        *)
            printf '%s\n' "  Slowest services:"

            while IFS= read -r service_record; do
                [[ -n "$service_record" ]] || continue

                service_name="${service_record%%|*}"
                duration="${service_record#*|}"

                if [[ "$service_name" == "$service_record" ]]; then
                    duration="unknown"
                fi

                printf '    %-40s %s\n' \
                    "$service_name" \
                    "$duration"
            done <<< "$slowest_services"
            ;;
    esac

    echo
    printf '%s\n' "Overall assessment:"
    printf '  Status:                  %s\n' "$health_status"
    printf '  Details:                 %s\n' "$health_details"
}

show_service_health() {
    draw_module_header "Service Health"

    log_info "Reading service health information..."
    echo

    print_service_health

    echo
    read -rp "Press Enter to continue..."
}
