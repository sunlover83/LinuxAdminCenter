#!/usr/bin/env bash

show_cli_help() {
    cat <<EOF
Linux Admin Center (LAC)

Usage:
  lac.sh
  lac.sh [OPTION]

Options:
  -h, --help       Show this help message
  -v, --version    Show version information

Without an option, LAC starts in interactive mode.
EOF
}

show_cli_version() {
    printf 'Linux Admin Center %s (%s)\n' \
        "$LAC_VERSION" \
        "$LAC_CODENAME"
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
        *)
            printf 'Error: Unknown option: %s\n\n' "$1" >&2
            show_cli_help >&2
            return 2
            ;;
    esac
}
