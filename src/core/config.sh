#!/usr/bin/env bash

# Configuration variables are used by other sourced modules.
# shellcheck disable=SC2034

LAC_DEBUG="false"

read_config_file() {
    local config_file="$1"
    local line
    local key
    local value

    [[ -r "$config_file" ]] || return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Remove comments and ignore empty lines.
        line="${line%%#*}"

        [[ -z "${line//[[:space:]]/}" ]] && continue

        if [[ "$line" =~ ^[[:space:]]*([A-Z_]+)[[:space:]]*=[[:space:]]*([^[:space:]]+)[[:space:]]*$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            case "$key" in
                DEBUG)
                    LAC_DEBUG="$value"
                    ;;
                *)
                    printf 'Warning: Unknown configuration option: %s\n' \
                        "$key" >&2
                    ;;
            esac
        else
            printf 'Warning: Invalid configuration line in %s: %s\n' \
                "$config_file" \
                "$line" >&2
        fi
    done < "$config_file"
}

validate_configuration() {
    case "$LAC_DEBUG" in
        true|false)
            ;;
        *)
            printf '%s\n' \
                "Warning: DEBUG must be 'true' or 'false'. Using 'false'." \
                >&2

            LAC_DEBUG="false"
            ;;
    esac
}

load_configuration() {
    local system_config
    local user_config

    system_config="${LAC_SYSTEM_CONFIG:-/etc/lac/lac.conf}"
    user_config="${LAC_USER_CONFIG:-${XDG_CONFIG_HOME:-${HOME}/.config}/lac/lac.conf}"

    read_config_file "$system_config"
    read_config_file "$user_config"
    validate_configuration
}
