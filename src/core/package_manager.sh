#!/usr/bin/env bash

is_package_manager_supported() {
    case "${PKG_MANAGER:-unknown}" in
        apt)
            command -v apt-get >/dev/null 2>&1
            ;;
        dnf)
            command -v dnf >/dev/null 2>&1
            ;;
        pacman)
            command -v pacman >/dev/null 2>&1 &&
                command -v checkupdates >/dev/null 2>&1
            ;;
        zypper)
            command -v zypper >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

refresh_package_information() {
    case "${PKG_MANAGER:-unknown}" in
        apt)
            sudo apt-get update
            ;;
        dnf)
            sudo dnf makecache --refresh
            ;;
        pacman)
            # checkupdates refreshes a separate temporary package database.
            return 0
            ;;
        zypper)
            sudo zypper --non-interactive refresh
            ;;
        *)
            return 2
            ;;
    esac
}

list_available_updates() {
    local status=0

    case "${PKG_MANAGER:-unknown}" in
        apt)
            apt list --upgradable 2>/dev/null | sed '1d'
            ;;
        dnf)
            dnf check-update --quiet || status=$?

            case "$status" in
                0|100)
                    return 0
                    ;;
                *)
                    return "$status"
                    ;;
            esac
            ;;
        pacman)
            checkupdates || status=$?

            case "$status" in
                0|2)
                    return 0
                    ;;
                *)
                    return "$status"
                    ;;
            esac
            ;;
        zypper)
            zypper --no-refresh --no-color list-updates 2>/dev/null |
                awk -F '|' '
                    $1 ~ /^[[:space:]]*v[[:space:]]*$/ {
                        for (i = 2; i <= 6; i++) {
                            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
                        }

                        printf "%s %s -> %s (%s)\n", \
                            $3, $4, $5, $6
                    }
                '
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
        dnf)
            sudo dnf upgrade --assumeyes
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
        zypper)
            case "${DISTRO_ID:-unknown}" in
                opensuse-tumbleweed)
                    sudo zypper --non-interactive dist-upgrade
                    ;;
                *)
                    sudo zypper --non-interactive update
                    ;;
            esac
            ;;
        *)
            return 2
            ;;
    esac
}
