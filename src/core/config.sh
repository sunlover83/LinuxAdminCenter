#!/usr/bin/env bash

# Configuration variables are used by other sourced modules.
# shellcheck disable=SC2034

LAC_DEBUG="false"

get_lac_user_config_path() {
    if [[ -n "${LAC_USER_CONFIG:-}" ]]; then
        printf '%s\n' "$LAC_USER_CONFIG"
    elif [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
        printf '%s/lac/lac.conf\n' "$XDG_CONFIG_HOME"
    elif [[ -n "${HOME:-}" ]]; then
        printf '%s/.config/lac/lac.conf\n' "$HOME"
    fi
}

read_config_file() {
    local config_file="$1"
    local line
    local key
    local value

    [[ -n "$config_file" && -r "$config_file" ]] || return 0

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
    user_config="$(get_lac_user_config_path)"

    read_config_file "$system_config"
    read_config_file "$user_config"
    validate_configuration
}
