#!/usr/bin/env bash

# Variables in this file are intentionally shared across sourced modules.
# shellcheck disable=SC2034

readonly LAC_VERSION="1.2.0"
readonly LAC_CODENAME="Release Automation"
readonly LAC_MIN_BASH_MAJOR=4
readonly LAC_MIN_BASH_MINOR=3

# ANSI colors
readonly COLOR_RESET="\033[0m"
readonly COLOR_RED="\033[31m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_CYAN="\033[36m"

is_bash_version_supported() {
    local major="$1"
    local minor="$2"

    [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1

    (( major > LAC_MIN_BASH_MAJOR ||
        (major == LAC_MIN_BASH_MAJOR && minor >= LAC_MIN_BASH_MINOR) ))
}

is_current_bash_version_supported() {
    is_bash_version_supported \
        "${BASH_VERSINFO[0]}" \
        "${BASH_VERSINFO[1]}"
}

require_supported_bash() {
    if is_current_bash_version_supported; then
        return 0
    fi

    printf 'Error: Linux Admin Center requires Bash %s.%s or newer (current: %s).\n' \
        "$LAC_MIN_BASH_MAJOR" \
        "$LAC_MIN_BASH_MINOR" \
        "$BASH_VERSION" >&2

    return 2
}

clear_screen() {
    clear
}

draw_module_header() {
    local title="$1"
    local width=41
    local title_width

    title_width=$(( (width + ${#title}) / 2 ))

    clear_screen

    printf '%s\n' "========================================="
    printf "%${title_width}s\n" "$title"
    printf '%s\n\n' "========================================="
}

log_info() {
    printf "${COLOR_BLUE}[INFO]${COLOR_RESET} %s\n" "$1"
}

log_debug() {
    [[ "${LAC_DEBUG:-false}" == "true" ]] || return 0

    printf "${COLOR_CYAN}[DEBUG]${COLOR_RESET} %s\n" "$1"
}

log_success() {
    printf "${COLOR_GREEN}[ OK ]${COLOR_RESET} %s\n" "$1"
}

log_warning() {
    printf "${COLOR_YELLOW}[WARN]${COLOR_RESET} %s\n" "$1"
}

log_error() {
    printf "${COLOR_RED}[FAIL]${COLOR_RESET} %s\n" "$1"
}

get_package_manager_for_distribution() {
    local distro_id="${1:-unknown}"
    local id_like="${2:-}"
    local like_id
    local -a like_ids=()

    case "$distro_id" in
        debian|ubuntu)
            printf '%s\n' "apt"
            return
            ;;
        fedora|rhel|centos)
            printf '%s\n' "dnf"
            return
            ;;
        arch)
            printf '%s\n' "pacman"
            return
            ;;
        opensuse*|sles|suse)
            printf '%s\n' "zypper"
            return
            ;;
    esac

    read -r -a like_ids <<< "$id_like"

    for like_id in "${like_ids[@]}"; do
        case "$like_id" in
            debian|ubuntu)
                printf '%s\n' "apt"
                return
                ;;
            fedora|rhel|centos)
                printf '%s\n' "dnf"
                return
                ;;
            arch)
                printf '%s\n' "pacman"
                return
                ;;
            opensuse*|sles|suse)
                printf '%s\n' "zypper"
                return
                ;;
        esac
    done

    printf '%s\n' "unknown"
}

detect_distribution() {
    local distro_id_like=""

    if [[ ! -r /etc/os-release ]]; then
        # shellcheck disable=SC2034
        DISTRO_ID="unknown"
        # shellcheck disable=SC2034
        DISTRO_NAME="Unknown Linux"
        # shellcheck disable=SC2034
        DISTRO_VERSION="unknown"
        # shellcheck disable=SC2034
        PKG_MANAGER="unknown"
        return
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    # shellcheck disable=SC2034
    DISTRO_ID="${ID:-unknown}"
    # shellcheck disable=SC2034
    DISTRO_NAME="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
    # shellcheck disable=SC2034
    DISTRO_VERSION="${VERSION_ID:-unknown}"
    distro_id_like="${ID_LIKE:-}"

    # shellcheck disable=SC2034
    PKG_MANAGER="$(
        get_package_manager_for_distribution \
            "$DISTRO_ID" \
            "$distro_id_like"
    )"
}

is_reboot_required() {
    [[ -f /var/run/reboot-required ]]
}
