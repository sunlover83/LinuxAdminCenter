#!/usr/bin/env bash

show_system_information() {
    detect_distribution
    draw_module_header "System Information"

    log_info "Reading system information..."
    echo

    echo "Distribution:    ${DISTRO_NAME}"
    echo "Distribution ID: ${DISTRO_ID}"
    echo "Version:         ${DISTRO_VERSION}"
    echo "Package manager: ${PKG_MANAGER}"
    echo

    if is_reboot_required; then
        log_warning "A system restart is required."
    else
        log_success "No system restart is required."
    fi

    echo
    read -rp "Press Enter to continue..."
}
