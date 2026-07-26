#!/usr/bin/env bash

check_for_updates() {
    local -a available_updates=()

    clear_screen
    detect_distribution

    echo "========================================="
    echo "          Check for Updates"
    echo "========================================="
    echo

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

show_update_menu() {
    local choice

    while true; do
        clear_screen

        echo "========================================="
        echo "          System Updates"
        echo "========================================="
        echo
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
                echo
                log_warning "Installing updates is not implemented yet."
                echo
                read -rp "Press Enter to continue..."
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
