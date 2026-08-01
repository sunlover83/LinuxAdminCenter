#!/usr/bin/env bash

get_package_cache_directory() {
    if [[ -n "${LAC_PACKAGE_CACHE_DIR:-}" ]]; then
        printf '%s\n' "$LAC_PACKAGE_CACHE_DIR"
        return
    fi

    case "${PKG_MANAGER:-unknown}" in
        apt)
            printf '%s\n' "/var/cache/apt/archives"
            ;;
        dnf)
            printf '%s\n' "/var/cache/dnf"
            ;;
        pacman)
            printf '%s\n' "/var/cache/pacman/pkg"
            ;;
        zypper)
            printf '%s\n' "/var/cache/zypp/packages"
            ;;
        *)
            printf '%s\n' "unknown"
            ;;
    esac
}

get_directory_size() {
    local directory="$1"
    local size

    if [[ ! -d "$directory" ]]; then
        printf '%s\n' "unavailable"
        return
    fi

    size="$(du -sh "$directory" 2>/dev/null | awk 'NR == 1 { print $1 }')"

    if [[ -n "$size" ]]; then
        printf '%s\n' "$size"
    else
        printf '%s\n' "unknown"
    fi
}

get_package_cache_size() {
    local cache_directory

    cache_directory="$(get_package_cache_directory)"

    if [[ "$cache_directory" == "unknown" ]]; then
        printf '%s\n' "unknown"
        return
    fi

    get_directory_size "$cache_directory"
}

get_journal_disk_usage() {
    local output

    if ! command -v journalctl >/dev/null 2>&1; then
        printf '%s\n' "unavailable"
        return
    fi

    output="$(LC_ALL=C journalctl --disk-usage 2>/dev/null || true)"

    if [[ -n "$output" ]]; then
        printf '%s\n' "$output"
    else
        printf '%s\n' "unknown"
    fi
}
