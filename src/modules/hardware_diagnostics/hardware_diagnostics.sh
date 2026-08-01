#!/usr/bin/env bash

print_hardware_diagnostics() {
    local sensors_status
    local nvidia_status
    local smartctl_status
    local nvme_status
    local cpu_temperature
    local nvidia_diagnostics
    local storage_diagnostics
    local diagnostic_line

    sensors_status="$(get_hardware_tool_status sensors)"
    nvidia_status="$(get_hardware_tool_status nvidia-smi)"
    smartctl_status="$(get_hardware_tool_status smartctl)"
    nvme_status="$(get_hardware_tool_status nvme)"

    cpu_temperature="$(get_cpu_temperature)"
    nvidia_diagnostics="$(get_nvidia_gpu_diagnostics)"
    storage_diagnostics="$(get_storage_diagnostics)"

    printf '%s\n' "Diagnostic tools:"
    printf '  sensors:      %s\n' "$sensors_status"
    printf '  nvidia-smi:   %s\n' "$nvidia_status"
    printf '  smartctl:     %s\n' "$smartctl_status"
    printf '  nvme:         %s\n' "$nvme_status"
    echo

    printf '%s\n' "Temperatures:"
    printf '  CPU:          %s\n' "$cpu_temperature"
    echo

    printf '%s\n' "NVIDIA GPUs:"

    while IFS= read -r diagnostic_line; do
        if [[ -n "$diagnostic_line" ]]; then
            printf '  %s\n' "$diagnostic_line"
        fi
    done <<< "$nvidia_diagnostics"

    echo
    printf '%s\n' "Storage devices:"

    while IFS= read -r diagnostic_line; do
        if [[ -n "$diagnostic_line" ]]; then
            printf '  %s\n' "$diagnostic_line"
        fi
    done <<< "$storage_diagnostics"
}

show_hardware_diagnostics() {
    draw_module_header "Hardware Diagnostics"

    log_info "Reading hardware diagnostics..."
    echo

    print_hardware_diagnostics

    echo
    read -rp "Press Enter to continue..."
}
