#!/usr/bin/env bash

is_hardware_tool_available() {
    local tool_name="$1"

    command -v "$tool_name" >/dev/null 2>&1
}

trim_hardware_value() {
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf '%s' "$value"
}

get_hardware_tool_status() {
    local tool_name="$1"

    if is_hardware_tool_available "$tool_name"; then
        printf '%s\n' "available"
    else
        printf '%s\n' "not installed"
    fi
}

get_cpu_temperature() {
    local temperature=""

    if ! is_hardware_tool_available sensors; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! temperature="$(
        LC_ALL=C sensors -u 2>/dev/null |
            awk '
                /^[[:alnum:]_.-]+$/ {
                    chip_name = $0
                    cpu_chip = chip_name ~ /^(coretemp|k10temp|zenpower|cpu_thermal)-/
                    next
                }

                cpu_chip &&
                /^[[:space:]]*temp[0-9]+_input:/ {
                    print $2
                    exit
                }
            '
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    if [[ "$temperature" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
        LC_NUMERIC=C printf '%.1f °C\n' "$temperature"
    else
        printf '%s\n' "unknown"
    fi
}

get_nvidia_gpu_diagnostics() {
    local query_output=""
    local gpu_index
    local gpu_name
    local temperature
    local utilization
    local memory_used
    local memory_total
    local result_found=false

    if ! is_hardware_tool_available nvidia-smi; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! query_output="$(
        nvidia-smi \
            --query-gpu=index,name,temperature.gpu,utilization.gpu,memory.used,memory.total \
            --format=csv,noheader,nounits \
            2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    while IFS=',' read -r \
        gpu_index \
        gpu_name \
        temperature \
        utilization \
        memory_used \
        memory_total; do

        gpu_index="$(trim_hardware_value "$gpu_index")"
        gpu_name="$(trim_hardware_value "$gpu_name")"
        temperature="$(trim_hardware_value "$temperature")"
        utilization="$(trim_hardware_value "$utilization")"
        memory_used="$(trim_hardware_value "$memory_used")"
        memory_total="$(trim_hardware_value "$memory_total")"

        if [[ -z "$gpu_index" || -z "$gpu_name" ]]; then
            continue
        fi

        printf 'GPU %s: %s | %s °C | %s%% | %s MiB / %s MiB\n' \
            "$gpu_index" \
            "$gpu_name" \
            "${temperature:-unknown}" \
            "${utilization:-unknown}" \
            "${memory_used:-unknown}" \
            "${memory_total:-unknown}"

        result_found=true
    done <<< "$query_output"

    if [[ "$result_found" == false ]]; then
        printf '%s\n' "unknown"
    fi
}

get_storage_devices() {
    local devices_output=""
    local device_name
    local device_type
    local device_size
    local device_model
    local result_found=false

    if ! is_hardware_tool_available lsblk; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! devices_output="$(
        LC_ALL=C lsblk -dn -b -o NAME,TYPE,SIZE,MODEL 2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    while read -r device_name device_type device_size device_model; do
        if [[ "$device_type" != "disk" || -z "$device_name" ]]; then
            continue
        fi

        if [[ "$device_name" == zram* ]]; then
            continue
        fi

        if [[ ! "$device_size" =~ ^[0-9]+$ ]] ||
            (( device_size == 0 )); then
            continue
        fi

        device_model="$(trim_hardware_value "${device_model:-}")"

        if [[ -z "$device_model" ]]; then
            device_model="unknown"
        fi

        printf '/dev/%s|%s\n' \
            "$device_name" \
            "$device_model"

        result_found=true
    done <<< "$devices_output"

    if [[ "$result_found" == false ]]; then
        printf '%s\n' "none"
    fi
}

get_smart_health_status() {
    local device="$1"
    local smart_output=""
    local normalized_output

    if ! is_hardware_tool_available smartctl; then
        printf '%s\n' "unavailable"
        return
    fi

    smart_output="$(
        LC_ALL=C smartctl -H "$device" 2>&1
    )" || true

    normalized_output="${smart_output,,}"

    if [[ "$normalized_output" == *"permission denied"* ]] ||
        [[ "$normalized_output" == *"operation not permitted"* ]]; then
        printf '%s\n' "requires root"
    elif [[ "$normalized_output" == *"passed"* ]] ||
        [[ "$normalized_output" == *"smart health status: ok"* ]]; then
        printf '%s\n' "healthy"
    elif [[ "$normalized_output" == *"failed"* ]] ||
        [[ "$normalized_output" == *"smart health status: bad"* ]]; then
        printf '%s\n' "warning"
    else
        printf '%s\n' "unknown"
    fi
}

get_nvme_health_status() {
    local device="$1"
    local nvme_output=""
    local normalized_output
    local critical_warning=""

    if ! is_hardware_tool_available nvme; then
        printf '%s\n' "unavailable"
        return
    fi

    nvme_output="$(
        LC_ALL=C nvme smart-log "$device" 2>&1
    )" || true

    normalized_output="${nvme_output,,}"

    if [[ "$normalized_output" == *"permission denied"* ]] ||
        [[ "$normalized_output" == *"operation not permitted"* ]]; then
        printf '%s\n' "requires root"
        return
    fi

    critical_warning="$(
        awk -F ':' '
            tolower($1) ~ /^[[:space:]]*critical_warning[[:space:]]*$/ {
                value = $2
                gsub(/[[:space:]]/, "", value)
                print tolower(value)
                exit
            }
        ' <<< "$nvme_output"
    )"

    if [[ "$critical_warning" =~ ^(0|0x0+)$ ]]; then
        printf '%s\n' "healthy"
    elif [[ -n "$critical_warning" ]]; then
        printf 'warning (critical_warning=%s)\n' \
            "$critical_warning"
    else
        printf '%s\n' "unknown"
    fi
}

get_storage_diagnostics() {
    local storage_devices
    local device
    local device_model
    local health_status

    storage_devices="$(get_storage_devices)"

    case "$storage_devices" in
        unavailable|unknown|none)
            printf '%s\n' "$storage_devices"
            return
            ;;
    esac

    while IFS='|' read -r device device_model; do
        if [[ -z "$device" ]]; then
            continue
        fi

        if [[ "$device" == /dev/nvme* ]]; then
            health_status="$(get_nvme_health_status "$device")"

            printf '%s: %s | NVMe health: %s\n' \
                "$device" \
                "$device_model" \
                "$health_status"
        else
            health_status="$(get_smart_health_status "$device")"

            printf '%s: %s | SMART health: %s\n' \
                "$device" \
                "$device_model" \
                "$health_status"
        fi
    done <<< "$storage_devices"
}
