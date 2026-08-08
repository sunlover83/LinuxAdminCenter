#!/usr/bin/env bash

collect_available_updates() {
    local target_name="$1"
    local output
    local status
    local -n target_ref="$target_name"

    target_ref=()

    if output="$(list_available_updates)"; then
        status=0
    else
        status=$?
    fi

    if (( status != 0 )); then
        return "$status"
    fi

    if [[ -n "$output" ]]; then
        # target_ref is a nameref to the caller's array.
        # shellcheck disable=SC2034
        mapfile -t target_ref <<< "$output"
    fi
}

check_for_updates_cli() {
    local -a available_updates=()

    detect_distribution

    if ! is_update_package_manager_supported; then
        printf "Error: Package manager '%s' is not supported for updates or required update tools are unavailable.\n" \
            "$PKG_MANAGER" >&2
        return 2
    fi

    printf '%s\n' "Refreshing package information..."

    if ! refresh_package_information; then
        printf '%s\n' \
            "Error: Package information could not be refreshed." >&2
        return 1
    fi

    if ! collect_available_updates available_updates; then
        printf '%s\n' \
            "Error: Available updates could not be determined." >&2
        return 1
    fi

    if (( ${#available_updates[@]} == 0 )); then
        printf '%s\n' "System is up to date."
        return 0
    fi

    printf '%s update(s) available.\n' \
        "${#available_updates[@]}"

    printf '%s\n' "${available_updates[@]}"

    return 10
}

check_for_updates() {
    local -a available_updates=()

    detect_distribution
    draw_module_header "Check for Updates"

    if ! is_update_package_manager_supported; then
        log_warning \
            "Package manager '${PKG_MANAGER}' is not supported for updates or required update tools are unavailable."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    log_info "Refreshing package information..."
    echo

    if ! refresh_package_information; then
        echo
        log_error "Package information could not be refreshed."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    if ! collect_available_updates available_updates; then
        echo
        log_error "Available updates could not be determined."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    echo

    if (( ${#available_updates[@]} == 0 )); then
        log_success "The system is up to date."
    else
        log_warning "${#available_updates[@]} update(s) available."
        echo
        printf '%s\n' "${available_updates[@]}"
    fi

    echo
    read -rp "Press Enter to continue..."
}

install_updates() {
    local -a available_updates=()
    local confirmation

    detect_distribution
    draw_module_header "Install Updates"

    if ! is_update_package_manager_supported; then
        log_warning \
            "Package manager '${PKG_MANAGER}' is not supported for updates or required update tools are unavailable."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    log_info "Refreshing package information..."
    echo

    if ! refresh_package_information; then
        echo
        log_error "Package information could not be refreshed."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    if ! collect_available_updates available_updates; then
        echo
        log_error "Available updates could not be determined."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    echo

    if (( ${#available_updates[@]} == 0 )); then
        log_success "The system is already up to date."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    log_warning "${#available_updates[@]} update(s) will be installed."
    echo

    printf '%s\n' "${available_updates[@]}"
    echo

    read -rp "Continue with installation? [y/N]: " confirmation

    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo
        log_info "Installation cancelled."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    echo
    log_info "Installing updates..."
    echo

    if install_available_updates; then
        echo
        log_success "Updates installed successfully."

        if is_reboot_required; then
            echo
            log_warning "A system restart is required."
        fi
    else
        echo
        log_error "Updates could not be installed completely."
    fi

    echo
    read -rp "Press Enter to continue..."
}

show_update_menu() {
    local choice

    while true; do
        draw_module_header "System Updates"

        echo "1) Check for updates"
        echo "2) Install updates"
        echo
        echo "0) Back"
        echo

        read -rp "Selection: " choice

        case "$choice" in
            1)
                check_for_updates
                ;;
            2)
                install_updates
                ;;
            0)
                return
                ;;
            *)
                echo
                log_warning "Invalid selection."
                sleep 1
                ;;
        esac
    done
}
