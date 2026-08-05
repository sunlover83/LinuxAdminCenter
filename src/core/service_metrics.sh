#!/usr/bin/env bash

is_service_tool_available() {
    local tool_name="$1"

    command -v "$tool_name" >/dev/null 2>&1
}

get_service_tool_status() {
    local tool_name="$1"

    if is_service_tool_available "$tool_name"; then
        printf '%s\n' "available"
    else
        printf '%s\n' "not installed"
    fi
}

get_init_system() {
    local proc_root="${LAC_PROC_ROOT:-/proc}"
    local init_name=""

    if is_service_tool_available ps; then
        init_name="$(
            LC_ALL=C ps -p 1 -o comm= 2>/dev/null |
                awk 'NF { print $1; exit }'
        )" || true
    fi

    if [[ -z "$init_name" &&
        -r "${proc_root}/1/comm" ]]; then
        IFS= read -r init_name < "${proc_root}/1/comm" || true
    fi

    init_name="${init_name##*/}"

    case "$init_name" in
        systemd)
            printf '%s\n' "systemd"
            ;;
        init|sysvinit)
            printf '%s\n' "sysvinit"
            ;;
        openrc|openrc-init)
            printf '%s\n' "openrc"
            ;;
        runit|runsvdir)
            printf '%s\n' "runit"
            ;;
        s6|s6-svscan)
            printf '%s\n' "s6"
            ;;
        *)
            printf '%s\n' "unknown"
            ;;
    esac
}

get_systemd_system_state() {
    local init_system
    local system_state=""

    init_system="$(get_init_system)"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' "unsupported"
        return
    fi

    if ! is_service_tool_available systemctl; then
        printf '%s\n' "unavailable"
        return
    fi

    system_state="$(
        LC_ALL=C systemctl is-system-running 2>/dev/null
    )" || true

    system_state="$(
        awk '
            NF {
                print tolower($1)
                exit
            }
        ' <<< "$system_state"
    )"

    case "$system_state" in
        initializing|starting|running|degraded|maintenance|stopping|offline)
            printf '%s\n' "$system_state"
            ;;
        *)
            printf '%s\n' "unknown"
            ;;
    esac
}

get_failed_systemd_services() {
    local init_system
    local service_output=""
    local failed_services=""

    init_system="$(get_init_system)"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' "unsupported"
        return
    fi

    if ! is_service_tool_available systemctl; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! service_output="$(
        LC_ALL=C systemctl list-units \
            --type=service \
            --state=failed \
            --no-legend \
            --no-pager \
            --plain \
            2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    failed_services="$(
        awk '
            NF {
                unit = $1

                if (unit == "●" && NF >= 2) {
                    unit = $2
                }

                if (unit ~ /[.]service$/) {
                    print unit
                }
            }
        ' <<< "$service_output"
    )"

    if [[ -n "$failed_services" ]]; then
        printf '%s\n' "$failed_services"
    else
        printf '%s\n' "none"
    fi
}

get_failed_systemd_service_count() {
    local failed_services

    failed_services="$(get_failed_systemd_services)"

    case "$failed_services" in
        unsupported|unavailable|unknown)
            printf '%s\n' "$failed_services"
            ;;
        none)
            printf '%s\n' "0"
            ;;
        *)
            awk 'NF { count++ } END { print count + 0 }' \
                <<< "$failed_services"
            ;;
    esac
}

get_systemd_service_counts() {
    local init_system
    local service_output=""

    init_system="$(get_init_system)"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' "unsupported"
        return
    fi

    if ! is_service_tool_available systemctl; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! service_output="$(
        LC_ALL=C systemctl list-units \
            --type=service \
            --all \
            --no-legend \
            --no-pager \
            --plain \
            2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    awk '
        NF {
            active_field = 3

            if ($1 == "●") {
                active_field = 4
            }

            state = $active_field

            if (state == "active") {
                active++
            } else if (state == "inactive") {
                inactive++
            } else if (state == "failed") {
                failed++
            }
        }

        END {
            printf \
                "active=%d|inactive=%d|failed=%d\n", \
                active + 0, \
                inactive + 0, \
                failed + 0
        }
    ' <<< "$service_output"
}

get_systemd_failed_service_details() {
    local service_name="${1:-}"
    local init_system
    local service_output=""
    local parsed_details=""

    if [[ ! "$service_name" =~ ^[[:alnum:]_.@:-]+[.]service$ ]]; then
        printf '%s\n' "invalid service"
        return
    fi

    init_system="$(get_init_system)"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' "unsupported"
        return
    fi

    if ! is_service_tool_available systemctl; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! service_output="$(
        LC_ALL=C systemctl show "$service_name" \
            --property=Id \
            --property=Description \
            --property=LoadState \
            --property=ActiveState \
            --property=SubState \
            --no-pager \
            2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    parsed_details="$(
        awk '
            function value_after_equals(line) {
                sub(/^[^=]*=/, "", line)
                return line
            }

            /^Id=/ {
                id = value_after_equals($0)
            }

            /^Description=/ {
                description = value_after_equals($0)
                gsub(/[|]/, "/", description)
            }

            /^LoadState=/ {
                load_state = value_after_equals($0)
            }

            /^ActiveState=/ {
                active_state = value_after_equals($0)
            }

            /^SubState=/ {
                sub_state = value_after_equals($0)
            }

            END {
                if (id == "" && description == "" &&
                    load_state == "" && active_state == "" &&
                    sub_state == "") {
                    exit
                }

                printf \
                    "unit=%s|description=%s|load=%s|active=%s|sub=%s\n", \
                    id, \
                    description, \
                    load_state, \
                    active_state, \
                    sub_state
            }
        ' <<< "$service_output"
    )"

    if [[ -n "$parsed_details" ]]; then
        printf '%s\n' "$parsed_details"
    else
        printf '%s\n' "unknown"
    fi
}

get_systemd_boot_time() {
    local init_system
    local analyze_output=""
    local boot_time=""

    init_system="$(get_init_system)"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' "unsupported"
        return
    fi

    if ! is_service_tool_available systemd-analyze; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! analyze_output="$(
        LC_ALL=C systemd-analyze time --no-pager 2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    boot_time="$(
        awk '
            /Startup finished in/ && /=/ {
                line = $0
                sub(/^.*=[[:space:]]*/, "", line)
                split(line, parts, /[[:space:]]+/)

                if (parts[1] != "") {
                    print parts[1]
                    exit
                }
            }
        ' <<< "$analyze_output"
    )"

    if [[ -n "$boot_time" ]]; then
        printf '%s\n' "$boot_time"
    else
        printf '%s\n' "unknown"
    fi
}

get_slowest_systemd_services() {
    local limit="${1:-5}"
    local init_system
    local analyze_output=""
    local parsed_services=""

    if [[ ! "$limit" =~ ^[1-9][0-9]*$ ]]; then
        printf '%s\n' "invalid limit"
        return
    fi

    init_system="$(get_init_system)"

    if [[ "$init_system" != "systemd" ]]; then
        printf '%s\n' "unsupported"
        return
    fi

    if ! is_service_tool_available systemd-analyze; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! analyze_output="$(
        LC_ALL=C systemd-analyze blame --no-pager 2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    parsed_services="$(
        awk -v limit="$limit" '
            NF >= 2 {
                unit = $NF

                if (unit !~ /[.]service$/) {
                    next
                }

                duration = $0
                sub(/[[:space:]]+[^[:space:]]+[[:space:]]*$/, "", duration)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", duration)

                if (duration == "") {
                    next
                }

                print unit "|" duration
                count++

                if (count >= limit) {
                    exit
                }
            }
        ' <<< "$analyze_output"
    )"

    if [[ -n "$parsed_services" ]]; then
        printf '%s\n' "$parsed_services"
    else
        printf '%s\n' "none"
    fi
}
