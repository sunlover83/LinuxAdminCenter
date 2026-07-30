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

get_cpu_model() {
    local cpu_model=""

    if command -v lscpu >/dev/null 2>&1; then
        cpu_model="$(
            LC_ALL=C lscpu 2>/dev/null |
                awk -F ':' '
                    /^Model name:/ {
                        value = $2
                        sub(/^[[:space:]]+/, "", value)
                        sub(/[[:space:]]+$/, "", value)
                        print value
                        exit
                    }
                '
        )"
    fi

    if [[ -z "$cpu_model" && -r /proc/cpuinfo ]]; then
        cpu_model="$(
            awk -F ':' '
                /^(model name|Hardware|Processor)[[:space:]]*:/ {
                    value = $2
                    sub(/^[[:space:]]+/, "", value)
                    sub(/[[:space:]]+$/, "", value)

                    if (value != "") {
                        print value
                        exit
                    }
                }
            ' /proc/cpuinfo 2>/dev/null
        )"
    fi

    if [[ -n "$cpu_model" ]]; then
        printf '%s\n' "$cpu_model"
        return
    fi

    if cpu_model="$(uname -p 2>/dev/null)" &&
        [[ -n "$cpu_model" && "$cpu_model" != "unknown" ]]; then
        printf '%s\n' "$cpu_model"
    else
        printf '%s\n' "unknown"
    fi
}

get_logical_cpu_count() {
    local cpu_count=""

    if command -v nproc >/dev/null 2>&1; then
        cpu_count="$(nproc 2>/dev/null || true)"

        if [[ "$cpu_count" =~ ^[0-9]+$ ]] &&
            (( cpu_count > 0 )); then
            printf '%s\n' "$cpu_count"
            return
        fi
    fi

    if [[ -r /proc/cpuinfo ]]; then
        cpu_count="$(
            awk -F ':' '
                /^[[:space:]]*processor[[:space:]]*:/ {
                    count++
                }

                END {
                    if (count > 0) {
                        print count
                    }
                }
            ' /proc/cpuinfo
        )"
    fi

    if [[ "$cpu_count" =~ ^[0-9]+$ ]] &&
        (( cpu_count > 0 )); then
        printf '%s\n' "$cpu_count"
    else
        printf '%s\n' "unknown"
    fi
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

format_kib() {
    local kib="$1"

    if [[ ! "$kib" =~ ^[0-9]+$ ]]; then
        printf '%s' "unknown"
        return
    fi

    awk -v kib="$kib" '
        BEGIN {
            if (kib >= 1048576) {
                printf "%.1f GiB", kib / 1048576
            } else {
                printf "%.1f MiB", kib / 1024
            }
        }
    '
}

get_memory_usage() {
    local mem_total_kib=""
    local mem_available_kib=""
    local mem_used_kib
    local usage_percentage
    local key
    local value

    if [[ ! -r /proc/meminfo ]]; then
        printf '%s\n' "unknown"
        return
    fi

    while read -r key value _; do
        case "$key" in
            MemTotal:)
                mem_total_kib="$value"
                ;;
            MemAvailable:)
                mem_available_kib="$value"
                ;;
        esac

        if [[ -n "$mem_total_kib" &&
            -n "$mem_available_kib" ]]; then
            break
        fi
    done < /proc/meminfo

    if [[ ! "$mem_total_kib" =~ ^[0-9]+$ ]] ||
        [[ ! "$mem_available_kib" =~ ^[0-9]+$ ]] ||
        (( mem_total_kib == 0 )); then
        printf '%s\n' "unknown"
        return
    fi

    mem_used_kib=$((mem_total_kib - mem_available_kib))
    usage_percentage=$((mem_used_kib * 100 / mem_total_kib))

    printf '%s / %s (%s%%)\n' \
        "$(format_kib "$mem_used_kib")" \
        "$(format_kib "$mem_total_kib")" \
        "$usage_percentage"
}

get_root_disk_usage() {
    local total_kib
    local used_kib
    local percentage

    if ! read -r total_kib used_kib percentage < <(
        df -Pk / 2>/dev/null |
            awk 'NR == 2 { print $2, $3, $5 }'
    ); then
        printf '%s\n' "unknown"
        return
    fi

    if [[ ! "$total_kib" =~ ^[0-9]+$ ]] ||
        [[ ! "$used_kib" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "unknown"
        return
    fi

    printf '%s / %s (%s)\n' \
        "$(format_kib "$used_kib")" \
        "$(format_kib "$total_kib")" \
        "$percentage"
}

get_load_average() {
    local load_one
    local load_five
    local load_fifteen

    if [[ ! -r /proc/loadavg ]]; then
        printf '%s\n' "unknown"
        return
    fi

    if read -r load_one load_five load_fifteen _ < /proc/loadavg; then
        printf '%s %s %s\n' \
            "$load_one" \
            "$load_five" \
            "$load_fifteen"
    else
        printf '%s\n' "unknown"
    fi
}

print_system_information() {
    local hostname_value
    local kernel_version
    local architecture
    local cpu_model
    local logical_cpu_count
    local uptime_value
    local memory_usage
    local root_disk_usage
    local load_average

    hostname_value="$(get_system_hostname)"
    kernel_version="$(get_kernel_version)"
    architecture="$(get_system_architecture)"
    cpu_model="$(get_cpu_model)"
    logical_cpu_count="$(get_logical_cpu_count)"
    uptime_value="$(get_system_uptime)"
    memory_usage="$(get_memory_usage)"
    root_disk_usage="$(get_root_disk_usage)"
    load_average="$(get_load_average)"

    printf 'Distribution:     %s\n' "$DISTRO_NAME"
    printf 'Distribution ID:  %s\n' "$DISTRO_ID"
    printf 'Version:          %s\n' "$DISTRO_VERSION"
    printf 'Package manager:  %s\n' "$PKG_MANAGER"
    printf 'Hostname:         %s\n' "$hostname_value"
    printf 'Kernel:           %s\n' "$kernel_version"
    printf 'Architecture:     %s\n' "$architecture"
    printf 'CPU:              %s\n' "$cpu_model"
    printf 'Logical CPUs:     %s\n' "$logical_cpu_count"
    printf 'Uptime:           %s\n' "$uptime_value"
    printf 'Memory:           %s\n' "$memory_usage"
    printf 'Root disk:        %s\n' "$root_disk_usage"
    printf 'Load average:     %s\n' "$load_average"
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
