#!/usr/bin/env bash

refresh_package_information() {
    case "${PKG_MANAGER:-unknown}" in
        apt)
            sudo apt-get update
            ;;
        *)
            return 2
            ;;
    esac
}

list_available_updates() {
    case "${PKG_MANAGER:-unknown}" in
        apt)
            apt list --upgradable 2>/dev/null | sed '1d'
            ;;
        *)
            return 2
            ;;
    esac
}

install_available_updates() {
    case "${PKG_MANAGER:-unknown}" in
        apt)
            sudo apt-get upgrade --assume-yes
            ;;
        *)
            return 2
            ;;
    esac
}
