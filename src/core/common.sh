#!/usr/bin/env bash

# Variables in this file are intentionally shared across sourced modules.
# shellcheck disable=SC2034

readonly LAC_VERSION="0.7.0-alpha"
readonly LAC_CODENAME="Services"

# ANSI colors
readonly COLOR_RESET="\033[0m"
readonly COLOR_RED="\033[31m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_CYAN="\033[36m"

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

detect_distribution() {
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

    case "$DISTRO_ID" in
        ubuntu|debian|pop|linuxmint)
            # shellcheck disable=SC2034
            PKG_MANAGER="apt"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            # shellcheck disable=SC2034
            PKG_MANAGER="dnf"
            ;;
        arch|manjaro)
            # shellcheck disable=SC2034
            PKG_MANAGER="pacman"
            ;;
        opensuse*|sles)
            # shellcheck disable=SC2034
            PKG_MANAGER="zypper"
            ;;
        *)
            # shellcheck disable=SC2034
            PKG_MANAGER="unknown"
            ;;
    esac
}

is_reboot_required() {
    [[ -f /var/run/reboot-required ]]
}
