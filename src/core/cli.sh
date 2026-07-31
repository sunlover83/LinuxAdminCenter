#!/usr/bin/env bash

show_cli_help() {
    cat <<EOF
Linux Admin Center (LAC)

Usage:
  lac.sh
  lac.sh [OPTION]

Options:
  -h, --help          Show this help message
  -v, --version       Show version information
  -i, --system-info   Show system information
  -n, --network-info  Show network information
  -u, --check-updates Check for available updates

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

show_cli_update_check() {
    check_for_updates_cli
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
        -u|--check-updates)
            show_cli_update_check
            ;;
        *)
            printf 'Error: Unknown option: %s\n\n' "$1" >&2
            show_cli_help >&2
            return 2
            ;;
    esac
}
