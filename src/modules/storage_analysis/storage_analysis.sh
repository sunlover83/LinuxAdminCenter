#!/usr/bin/env bash

readonly STORAGE_WARNING_PERCENTAGE=80
readonly STORAGE_CRITICAL_PERCENTAGE=90

format_storage_kib() {
    local kib="$1"

    if [[ ! "$kib" =~ ^-?[0-9]+$ ]]; then
        printf '%s' "unknown"
        return
    fi

    LC_ALL=C awk -v kib="$kib" '
        BEGIN {
            absolute_kib = kib < 0 ? -kib : kib

            if (absolute_kib >= 1073741824) {
                printf "%.1f TiB", kib / 1073741824
            } else if (absolute_kib >= 1048576) {
                printf "%.1f GiB", kib / 1048576
            } else if (absolute_kib >= 1024) {
                printf "%.1f MiB", kib / 1024
            } else {
                printf "%s KiB", kib
            }
        }
    '
}

get_storage_usage_status() {
    local percentage="$1"

    if [[ ! "$percentage" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "incomplete"
    elif (( percentage >= STORAGE_CRITICAL_PERCENTAGE )); then
        printf '%s\n' "critical"
    elif (( percentage >= STORAGE_WARNING_PERCENTAGE )); then
        printf '%s\n' "warning"
    else
        printf '%s\n' "healthy"
    fi
}

get_storage_record_status() {
    local capacity_percentage="$1"
    local inode_percentage="$2"
    local capacity_status
    local inode_status="not-applicable"

    capacity_status="$(get_storage_usage_status "$capacity_percentage")"

    if [[ "$inode_percentage" != "not-applicable" ]]; then
        inode_status="$(get_storage_usage_status "$inode_percentage")"
    fi

    if [[ "$capacity_status" == "critical" ||
        "$inode_status" == "critical" ]]; then
        printf '%s\n' "critical"
    elif [[ "$capacity_status" == "warning" ||
        "$inode_status" == "warning" ]]; then
        printf '%s\n' "warning"
    elif [[ "$capacity_status" == "incomplete" ||
        "$inode_status" == "incomplete" ]]; then
        printf '%s\n' "incomplete"
    else
        printf '%s\n' "healthy"
    fi
}

get_storage_analysis_summary() {
    local records="${1:-$(get_storage_filesystem_records)}"
    local source
    local filesystem_type
    local total_kib
    local used_kib
    local available_kib
    local capacity_percentage
    local inode_total
    local inode_used
    local _inode_available
    local inode_percentage
    local mountpoint
    local record_status
    local overall_status="healthy"
    local record_found=false

    case "$records" in
        unavailable|unknown|none|"")
            printf '%s\n' "incomplete"
            return
            ;;
    esac

    while IFS='|' read -r \
        source \
        filesystem_type \
        total_kib \
        used_kib \
        available_kib \
        capacity_percentage \
        inode_total \
        inode_used \
        _inode_available \
        inode_percentage \
        mountpoint; do

        [[ -n "$mountpoint" ]] || continue
        record_found=true

        record_status="$(
            get_storage_record_status \
                "$capacity_percentage" \
                "$inode_percentage"
        )"

        case "$record_status" in
            critical)
                overall_status="critical"
                ;;
            warning)
                if [[ "$overall_status" != "critical" ]]; then
                    overall_status="warning"
                fi
                ;;
            incomplete)
                if [[ "$overall_status" == "healthy" ]]; then
                    overall_status="incomplete"
                fi
                ;;
        esac
    done <<< "$records"

    if [[ "$record_found" == false ]]; then
        printf '%s\n' "incomplete"
    else
        printf '%s\n' "$overall_status"
    fi
}

get_storage_analysis_summary_message() {
    local status="$1"

    case "$status" in
        healthy)
            printf '%s\n' \
                "All analyzed filesystems are below the warning thresholds."
            ;;
        warning)
            printf '%s\n' \
                "At least one filesystem has reached a warning threshold."
            ;;
        critical)
            printf '%s\n' \
                "At least one filesystem has reached a critical threshold."
            ;;
        incomplete|*)
            printf '%s\n' \
                "A complete storage assessment could not be determined."
            ;;
    esac
}

print_storage_status_legend() {
    printf '%s\n' "Status meanings:"
    printf '  %-12s %s\n' \
        "healthy:" \
        "All evaluated capacity and inode values are below 80%."
    printf '  %-12s %s\n' \
        "warning:" \
        "At least one value is between 80% and 89%; none is critical."
    printf '  %-12s %s\n' \
        "critical:" \
        "At least one value is 90% or higher."
    printf '  %-12s %s\n' \
        "incomplete:" \
        "Available data is insufficient for a complete assessment."
}

print_storage_recommendations() {
    local status="$1"

    printf '%s\n' "Recommended next steps:"

    case "$status" in
        healthy)
            printf '%s\n' \
                "  - No immediate action is required; continue monitoring."
            ;;
        warning)
            printf '%s\n' \
                "  - Review filesystems marked warning and identify the triggering metric."
            printf '%s\n' \
                "  - Run lac --cleanup-report for a read-only review of cleanup candidates."
            printf '%s\n' \
                "  - Back up important data before cleanup, resizing or storage expansion."
            printf '%s\n' \
                "  - For capacity pressure, archive or remove only verified unnecessary data."
            printf '%s\n' \
                "  - For inode pressure, investigate directories containing many small files."
            ;;
        critical)
            printf '%s\n' \
                "  - Act promptly and identify the metric on filesystems marked critical."
            printf '%s\n' \
                "  - Run lac --cleanup-report for a read-only review of cleanup candidates."
            printf '%s\n' \
                "  - Back up important data before cleanup, resizing or storage expansion."
            printf '%s\n' \
                "  - For capacity pressure, archive or remove only verified unnecessary data."
            printf '%s\n' \
                "  - For inode pressure, investigate directories containing many small files."
            ;;
        incomplete|*)
            printf '%s\n' \
                "  - Check df availability, filesystem access and expected mount state."
            printf '%s\n' \
                "  - Do not treat an incomplete assessment as healthy."
            ;;
    esac
}

print_storage_filesystem_record() {
    local source="$1"
    local filesystem_type="$2"
    local total_kib="$3"
    local used_kib="$4"
    local available_kib="$5"
    local capacity_percentage="$6"
    local inode_total="$7"
    local inode_used="$8"
    local inode_percentage="$9"
    local mountpoint="${10}"
    local record_status

    record_status="$(
        get_storage_record_status \
            "$capacity_percentage" \
            "$inode_percentage"
    )"

    printf '  %s (%s)\n' "$mountpoint" "$filesystem_type"
    printf '    %-12s %s\n' "Source:" "$source"
    printf '    %-12s %s / %s (%s%% used, %s available)\n' \
        "Capacity:" \
        "$(format_storage_kib "$used_kib")" \
        "$(format_storage_kib "$total_kib")" \
        "$capacity_percentage" \
        "$(format_storage_kib "$available_kib")"

    if [[ "$inode_percentage" == "not-applicable" ]]; then
        printf '    %-12s %s\n' "Inodes:" "not applicable"
    else
        printf '    %-12s %s / %s (%s%% used)\n' \
            "Inodes:" \
            "$inode_used" \
            "$inode_total" \
            "$inode_percentage"
    fi

    printf '    %-12s %s\n' "Status:" "$record_status"
}

print_storage_analysis() {
    local records
    local source
    local filesystem_type
    local total_kib
    local used_kib
    local available_kib
    local capacity_percentage
    local inode_total
    local inode_used
    local _inode_available
    local inode_percentage
    local mountpoint
    local overall_status
    local details

    records="$(get_storage_filesystem_records)"
    overall_status="$(get_storage_analysis_summary "$records")"
    details="$(get_storage_analysis_summary_message "$overall_status")"

    printf '%s\n' "Thresholds:"
    printf '  %-12s %s%%\n' "Warning:" "$STORAGE_WARNING_PERCENTAGE"
    printf '  %-12s %s%%\n' "Critical:" "$STORAGE_CRITICAL_PERCENTAGE"
    echo

    print_storage_status_legend
    echo

    printf '%s\n' "Filesystems:"

    case "$records" in
        unavailable)
            printf '%s\n' "  unavailable (df is not installed)"
            ;;
        unknown)
            printf '%s\n' "  unknown (filesystem data could not be read)"
            ;;
        none|"")
            printf '%s\n' "  none (no persistent local filesystems found)"
            ;;
        *)
            while IFS='|' read -r \
                source \
                filesystem_type \
                total_kib \
                used_kib \
                available_kib \
                capacity_percentage \
                inode_total \
                inode_used \
                _inode_available \
                inode_percentage \
                mountpoint; do

                [[ -n "$mountpoint" ]] || continue

                source="$(decode_storage_record_field "$source")"
                filesystem_type="$(
                    decode_storage_record_field "$filesystem_type"
                )"
                mountpoint="$(decode_storage_record_field "$mountpoint")"

                print_storage_filesystem_record \
                    "$source" \
                    "$filesystem_type" \
                    "$total_kib" \
                    "$used_kib" \
                    "$available_kib" \
                    "$capacity_percentage" \
                    "$inode_total" \
                    "$inode_used" \
                    "$inode_percentage" \
                    "$mountpoint"
                echo
            done <<< "$records"
            ;;
    esac

    echo
    printf '%s\n' "Overall storage assessment:"
    printf '  %-12s %s\n' "Status:" "$overall_status"
    printf '  %-12s %s\n' "Details:" "$details"
    echo
    print_storage_recommendations "$overall_status"
}

show_storage_analysis() {
    draw_module_header "Storage Analysis"

    log_info "Reading storage usage..."
    echo

    print_storage_analysis

    echo
    read -rp "Press Enter to continue..."
}
