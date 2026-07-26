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
    echo
    echo "0) Exit"
    echo
}

read_choice() {
    read -rp "Selection: " choice

    case "$choice" in
        1)
             echo
             echo "System Updates - coming soon..."
             read -rp "Press Enter to continue..."
             ;;
        2)
            echo
            echo "System Information - coming soon..."
            read -rp "Press Enter to continue..."
            ;;
        0)
            echo
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo
            echo "Invalid selection."
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
