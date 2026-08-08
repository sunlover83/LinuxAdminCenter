#!/usr/bin/env bash

get_lac_self_check_status() {
    local bash_status="${1:-$(get_bash_runtime_status)}"
    local runtime_status="${2:-$(get_lac_runtime_files_status)}"
    local launcher_status="${3:-$(get_lac_launcher_status)}"
    local required_tools_status="${4:-$(get_lac_required_tools_status)}"
    local system_config_status="${5:-$(get_lac_system_config_status)}"
    local user_config_status="${6:-$(get_lac_user_config_status)}"
    local package_manager_status="${7:-$(get_lac_package_manager_status)}"

    if [[ "$bash_status" == unsupported* ]] ||
        [[ "$runtime_status" == missing* ]] ||
        [[ "$launcher_status" == "incomplete" ]]; then
        printf '%s\n' "failed"
        return
    fi

    if [[ "$required_tools_status" == missing* ]] ||
        [[ "$system_config_status" == "not readable" ]] ||
        [[ "$user_config_status" == "not readable" ]] ||
        [[ "$package_manager_status" == *"|unavailable" ]]; then
        printf '%s\n' "warning"
        return
    fi

    printf '%s\n' "healthy"
}

get_lac_self_check_message() {
    local status="$1"
    local bash_status="$2"
    local runtime_status="$3"
    local launcher_status="$4"
    local required_tools_status="$5"
    local system_config_status="$6"
    local user_config_status="$7"
    local package_manager_status="$8"

    if [[ "$bash_status" == unsupported* ]]; then
        printf '%s\n' "The active Bash version is older than the supported minimum of 4.3."
    elif [[ "$runtime_status" == missing* ]]; then
        printf '%s\n' "Required Linux Admin Center runtime files are missing."
    elif [[ "$launcher_status" == "incomplete" ]]; then
        printf '%s\n' "The system-wide installation is missing one or more LAC launcher commands."
    elif [[ "$required_tools_status" == missing* ]]; then
        printf '%s\n' "One or more core command-line tools required by LAC are missing."
    elif [[ "$system_config_status" == "not readable" ]] ||
        [[ "$user_config_status" == "not readable" ]]; then
        printf '%s\n' "A configured LAC configuration file exists but cannot be read."
    elif [[ "$package_manager_status" == *"|unavailable" ]]; then
        printf '%s\n' "The detected package manager is unsupported or unavailable, so update and cleanup features are limited."
    elif [[ "$status" == "healthy" ]]; then
        printf '%s\n' "The LAC runtime, launchers, configuration handling and required core tools are ready."
    else
        printf '%s\n' "The LAC self-check could not determine a complete status."
    fi
}

print_lac_tool_records() {
    local records="$1"
    local name
    local status

    while IFS='|' read -r name status; do
        [[ -n "$name" ]] || continue
        printf '  %-23s %s\n' "${name}:" "$status"
    done <<< "$records"
}

print_lac_self_check() {
    local runtime_root
    local installation_type
    local bash_status
    local runtime_status
    local launcher_status
    local system_config_status
    local user_config_status
    local required_tools_status
    local required_tool_records
    local optional_tool_records
    local package_manager_status
    local package_manager_name
    local package_manager_availability
    local overall_status
    local details

    runtime_root="$(get_lac_runtime_root)"
    installation_type="$(get_lac_installation_type "$runtime_root")"
    bash_status="$(get_bash_runtime_status)"
    runtime_status="$(get_lac_runtime_files_status "$runtime_root")"
    launcher_status="$(get_lac_launcher_status "$runtime_root")"
    system_config_status="$(get_lac_system_config_status)"
    user_config_status="$(get_lac_user_config_status)"
    required_tools_status="$(get_lac_required_tools_status)"
    required_tool_records="$(get_lac_required_tool_records)"
    optional_tool_records="$(get_lac_optional_tool_records)"
    package_manager_status="$(get_lac_package_manager_status)"
    IFS='|' read -r package_manager_name package_manager_availability <<< "$package_manager_status"

    overall_status="$(
        get_lac_self_check_status \
            "$bash_status" \
            "$runtime_status" \
            "$launcher_status" \
            "$required_tools_status" \
            "$system_config_status" \
            "$user_config_status" \
            "$package_manager_status"
    )"

    details="$(
        get_lac_self_check_message \
            "$overall_status" \
            "$bash_status" \
            "$runtime_status" \
            "$launcher_status" \
            "$required_tools_status" \
            "$system_config_status" \
            "$user_config_status" \
            "$package_manager_status"
    )"

    printf '%s\n' "LAC runtime:"
    printf '  %-23s %s (%s)\n' "Version:" "$LAC_VERSION" "$LAC_CODENAME"
    printf '  %-23s %s\n' "Bash:" "$bash_status"
    printf '  %-23s %s\n' "Installation:" "$installation_type"
    printf '  %-23s %s\n' "Runtime root:" "$runtime_root"
    printf '  %-23s %s\n' "Runtime files:" "$runtime_status"
    printf '  %-23s %s\n' "Launchers:" "$launcher_status"
    echo

    printf '%s\n' "Configuration:"
    printf '  %-23s %s\n' "System configuration:" "$system_config_status"
    printf '  %-23s %s\n' "User configuration:" "$user_config_status"
    echo

    printf '%s\n' "Core tools:"
    print_lac_tool_records "$required_tool_records"
    printf '  %-23s %s (%s)\n' \
        "Package manager:" \
        "$package_manager_name" \
        "$package_manager_availability"
    echo

    printf '%s\n' "Optional diagnostics:"
    print_lac_tool_records "$optional_tool_records"
    echo

    printf '%s\n' "Overall self-check:"
    printf '  %-23s %s\n' "Status:" "$overall_status"
    printf '  %-23s %s\n' "Details:" "$details"
}

show_lac_self_check() {
    draw_module_header "LAC Self Check"
    print_lac_self_check
    echo
    read -rp "Press Enter to continue..."
}
