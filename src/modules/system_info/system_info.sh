#!/usr/bin/env bash

show_system_information() {
    detect_distribution
    clear_screen

    log_info "Reading system information..."

    echo
    echo "========================================="
    echo "          System Information"
    echo "========================================="
    echo
    echo "Distribution:    ${DISTRO_NAME}"
    echo "Distribution ID: ${DISTRO_ID}"
    echo "Version:         ${DISTRO_VERSION}"
    echo "Package manager: ${PKG_MANAGER}"
    echo

    read -rp "Press Enter to continue..."
}
