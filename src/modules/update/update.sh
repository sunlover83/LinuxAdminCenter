#!/usr/bin/env bash

check_for_updates() {
    local -a available_updates=()

    clear_screen
    detect_distribution

    detect_distribution
    draw_module_header "Check for Updates"

    if [[ "$PKG_MANAGER" != "apt" ]]; then
        log_warning "Package manager '${PKG_MANAGER}' is not supported yet."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    log_info "Refreshing package information..."
    echo

    if ! sudo apt-get update; then
        echo
        log_error "Package information could not be refreshed."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    mapfile -t available_updates < <(
        apt list --upgradable 2>/dev/null | sed '1d'
    )

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

    if [[ "$PKG_MANAGER" != "apt" ]]; then
        log_warning "Package manager '${PKG_MANAGER}' is not supported yet."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    log_info "Refreshing package information..."
    echo

    if ! sudo apt-get update; then
        echo
        log_error "Package information could not be refreshed."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    mapfile -t available_updates < <(
        apt list --upgradable 2>/dev/null | sed '1d'
    )

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

    if sudo apt-get upgrade --assume-yes; then
        echo
        log_success "Updates installed successfully."
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
        clear_screen

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
