#!/usr/bin/env bash

print_system_information() {
    printf 'Distribution:     %s\n' "$DISTRO_NAME"
    printf 'Distribution ID:  %s\n' "$DISTRO_ID"
    printf 'Version:          %s\n' "$DISTRO_VERSION"
    printf 'Package manager:  %s\n' "$PKG_MANAGER"
}

print_reboot_status() {
    if is_reboot_required; then
        printf '%s\n' "Restart required: Yes"
    else
        printf '%s\n' "Restart required: No"
    fi
}

show_system_information() {
    detect_distribution
    draw_module_header "System Information"

    log_debug "Distribution detection completed."
    log_info "Reading system information..."
    echo

    print_system_information
    echo

    if is_reboot_required; then
        log_warning "A system restart is required."
    else
        log_success "No system restart is required."
    fi

    echo
    read -rp "Press Enter to continue..."
}
