#!/usr/bin/env bash

collect_unneeded_packages() {
    local target_name="$1"
    local output
    local status
    local -n target_ref="$target_name"

    target_ref=()

    if output="$(list_unneeded_packages)"; then
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

print_cleanup_report() {
    local cache_directory
    local cache_size
    local journal_usage
    local -a unneeded_packages=()

    detect_distribution

    if ! is_package_manager_supported; then
        printf "Error: Package manager '%s' is not supported or unavailable.\n" \
            "$PKG_MANAGER" >&2
        return 2
    fi

    cache_directory="$(get_package_cache_directory)"
    cache_size="$(get_package_cache_size)"
    journal_usage="$(get_journal_disk_usage)"

    if ! collect_unneeded_packages unneeded_packages; then
        printf '%s\n' \
            "Error: Packages no longer required could not be determined." \
            >&2
        return 1
    fi

    printf 'Package manager:       %s\n' "$PKG_MANAGER"
    printf 'Package cache:         %s\n' "$cache_directory"
    printf 'Package cache size:    %s\n' "$cache_size"
    printf 'System journal usage:  %s\n' "$journal_usage"
    printf 'Unneeded packages:     %s\n' "${#unneeded_packages[@]}"

    if (( ${#unneeded_packages[@]} > 0 )); then
        echo
        printf '%s\n' "${unneeded_packages[@]}"
    fi
}

show_cleanup_report() {
    draw_module_header "System Cleanup Report"

    log_info "Analyzing cleanup candidates..."
    echo

    if ! print_cleanup_report; then
        echo
        log_error "The cleanup report could not be completed."
    fi

    echo
    read -rp "Press Enter to continue..."
}

run_package_cache_cleanup() {
    local cache_directory
    local cache_size_before
    local cache_size_after
    local confirmation

    detect_distribution
    draw_module_header "Clean Package Cache"

    if ! is_package_manager_supported; then
        log_warning \
            "Package manager '${PKG_MANAGER}' is not supported or unavailable."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    if ! is_package_cache_cleanup_supported; then
        log_warning "Package cache cleanup is unavailable."

        if [[ "$PKG_MANAGER" == "pacman" ]]; then
            echo
            printf '%s\n' \
                "Install pacman-contrib to provide the paccache command."
        fi

        echo
        read -rp "Press Enter to continue..."
        return
    fi

    cache_directory="$(get_package_cache_directory)"
    cache_size_before="$(get_package_cache_size)"

    printf 'Package manager:    %s\n' "$PKG_MANAGER"
    printf 'Package cache:      %s\n' "$cache_directory"
    printf 'Current cache size: %s\n' "$cache_size_before"

    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        echo
        printf '%s\n' \
            "Pacman cleanup keeps the two newest cached versions per package."
    fi

    echo
    read -rp "Continue with package cache cleanup? [y/N]: " confirmation

    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo
        log_info "Package cache cleanup cancelled."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    echo
    log_info "Cleaning package cache..."
    echo

    if clean_package_cache; then
        cache_size_after="$(get_package_cache_size)"
        log_success "Package cache cleaned successfully."
        printf 'Cache size before: %s\n' "$cache_size_before"
        printf 'Cache size after:  %s\n' "$cache_size_after"
    else
        log_error "Package cache cleanup failed."
    fi

    echo
    read -rp "Press Enter to continue..."
}

run_unneeded_package_cleanup() {
    local confirmation
    local -a unneeded_packages=()

    detect_distribution
    draw_module_header "Remove Unneeded Packages"

    if ! is_package_manager_supported; then
        log_warning \
            "Package manager '${PKG_MANAGER}' is not supported or unavailable."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    log_info "Searching for packages no longer required..."
    echo

    if ! collect_unneeded_packages unneeded_packages; then
        log_error "Packages no longer required could not be determined."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    if (( ${#unneeded_packages[@]} == 0 )); then
        log_success "No unneeded packages were found."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    log_warning \
        "${#unneeded_packages[@]} package(s) are classified as no longer required."
    echo
    printf '%s\n' "${unneeded_packages[@]}"
    echo
    printf '%s\n' \
        "Review the list carefully. Removing packages changes the system."
    echo

    read -rp "Type REMOVE to continue: " confirmation

    if [[ "$confirmation" != "REMOVE" ]]; then
        echo
        log_info "Package removal cancelled."
        echo
        read -rp "Press Enter to continue..."
        return
    fi

    echo
    log_info "Removing packages no longer required..."
    echo

    if remove_unneeded_packages; then
        log_success "Unneeded packages removed successfully."
    else
        log_error "Unneeded packages could not be removed completely."
    fi

    echo
    read -rp "Press Enter to continue..."
}

show_cleanup_menu() {
    local choice

    while true; do
        draw_module_header "System Cleanup"

        echo "1) Show cleanup report"
        echo "2) Clean package cache"
        echo "3) Remove unneeded packages"
        echo
        echo "0) Back"
        echo

        read -rp "Selection: " choice

        case "$choice" in
            1)
                show_cleanup_report
                ;;
            2)
                run_package_cache_cleanup
                ;;
            3)
                run_unneeded_package_cleanup
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
