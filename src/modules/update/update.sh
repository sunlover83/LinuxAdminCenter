#!/usr/bin/env bash

show_update_menu() {
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
                echo
                echo "Check for updates - coming soon..."
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo
                echo "Install updates - coming soon..."
                read -rp "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                echo
                echo "Invalid selection."
                sleep 1
                ;;
        esac
    done
}
