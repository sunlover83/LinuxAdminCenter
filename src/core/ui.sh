#!/usr/bin/env bash

draw_header() {
    clear_screen

    echo "========================================="
    echo "      Linux Admin Center (LAC)"
    echo "========================================="
    echo
    echo "Version : ${LAC_VERSION}"
    echo "Codename: ${LAC_CODENAME}"
    echo
}

draw_main_menu() {
    echo "1) System Updates"
    echo "2) System Information"
    echo "3) Network Information"
    echo "4) System Cleanup"
    echo "5) Hardware Diagnostics"
    echo "6) Network Diagnostics"
    echo "7) Gaming Readiness"
    echo "8) Service Health"
    echo "9) Gaming Diagnostics"
    echo
    echo "0) Exit"
    echo
}

read_choice() {
    local choice

    read -rp "Selection: " choice

    case "$choice" in
        1)
            show_update_menu
            ;;
        2)
            show_system_information
            ;;
        3)
            show_network_information
            ;;
        4)
            show_cleanup_menu
            ;;
        5)
            show_hardware_diagnostics
            ;;
        6)
            show_network_diagnostics
            ;;
        7)
            show_gaming_readiness
            ;;
        8)
            show_service_health
            ;;
        9)
            show_gaming_diagnostics
            ;;
        0)
            echo
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo
            log_warning "Invalid selection."
            sleep 1
            ;;
    esac
}

main() {
    while true; do
        draw_header
        draw_main_menu
        read_choice
    done
}
