#!/usr/bin/env bash

show_cli_help() {
    cat <<EOF
Linux Admin Center (LAC)

Usage:
  lac
  lac [OPTION]

Options:
  -h, --help                   Show this help message
  -v, --version                Show version information
  -i, --system-info            Show system information
  -n, --network-info           Show network information
  -r, --network-diagnostics    Show network diagnostics
  -d, --hardware-diagnostics   Show hardware diagnostics
  -g, --gaming-readiness       Show gaming readiness
  -G, --gaming-diagnostics     Show detailed gaming diagnostics
  -e, --service-health         Show service health
  -S, --self-check             Check the LAC runtime and dependencies
  -u, --check-updates          Check for available updates
  -c, --cleanup-report         Show a read-only cleanup report

Without an option, LAC starts in interactive mode.
EOF
}

show_cli_version() {
    printf 'Linux Admin Center %s (%s)\n' \
        "$LAC_VERSION" \
        "$LAC_CODENAME"
}

show_cli_system_information() {
    detect_distribution

    print_system_information
    print_reboot_status
}

show_cli_network_information() {
    print_network_information
}

show_cli_network_diagnostics() {
    print_network_diagnostics
}

show_cli_hardware_diagnostics() {
    print_hardware_diagnostics
}

show_cli_gaming_readiness() {
    print_gaming_readiness
}

show_cli_gaming_diagnostics() {
    print_gaming_diagnostics
}

show_cli_service_health() {
    print_service_health
}

show_cli_self_check() {
    print_lac_self_check
}

show_cli_update_check() {
    check_for_updates_cli
}

show_cli_cleanup_report() {
    print_cleanup_report
}

handle_cli_arguments() {
    if (( $# != 1 )); then
        printf '%s\n\n' "Error: Exactly one option is expected." >&2
        show_cli_help >&2
        return 2
    fi

    case "$1" in
        -h|--help)
            show_cli_help
            ;;
        -v|--version)
            show_cli_version
            ;;
        -i|--system-info)
            show_cli_system_information
            ;;
        -n|--network-info)
            show_cli_network_information
            ;;
        -r|--network-diagnostics)
            show_cli_network_diagnostics
            ;;
        -d|--hardware-diagnostics)
            show_cli_hardware_diagnostics
            ;;
        -g|--gaming-readiness)
            show_cli_gaming_readiness
            ;;
        -G|--gaming-diagnostics)
            show_cli_gaming_diagnostics
            ;;
        -e|--service-health)
            show_cli_service_health
            ;;
        -S|--self-check)
            show_cli_self_check
            ;;
        -u|--check-updates)
            show_cli_update_check
            ;;
        -c|--cleanup-report)
            show_cli_cleanup_report
            ;;
        *)
            printf 'Error: Unknown option: %s\n\n' "$1" >&2
            show_cli_help >&2
            return 2
            ;;
    esac
}
