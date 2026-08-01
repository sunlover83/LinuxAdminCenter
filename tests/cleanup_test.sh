#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAC_SCRIPT="${PROJECT_ROOT}/src/lac.sh"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"
MOCK_CACHE="${TEST_TMP_DIR}/cache"

mkdir -p "$MOCK_BIN" "$MOCK_CACHE"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${PATH}"
export LAC_PACKAGE_CACHE_DIR="$MOCK_CACHE"

passed=0
failed=0

pass_test() {
    printf '[PASS] %s\n' "$1"
    passed=$((passed + 1))
}

fail_test() {
    printf '[FAIL] %s\n' "$1"
    failed=$((failed + 1))
}

create_mock() {
    local command_name="$1"

    cat > "${MOCK_BIN}/${command_name}"
    chmod +x "${MOCK_BIN}/${command_name}"
}

assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Actual:   %s\n' "$actual"
    fi
}

assert_output_contains() {
    local description="$1"
    local expected="$2"
    local output
    local status

    shift 2

    if output=$("$@" 2>&1); then
        status=0
    else
        status=$?
    fi

    if (( status == 0 )) && [[ "$output" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Output:   %s\n' "$output"
        printf '       Status:   %s\n' "$status"
    fi
}

assert_exit_status() {
    local description="$1"
    local expected_status="$2"
    local actual_status

    shift 2

    if "$@" >/dev/null 2>&1; then
        actual_status=0
    else
        actual_status=$?
    fi

    if (( actual_status == expected_status )); then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected status: %s\n' "$expected_status"
        printf '       Actual status:   %s\n' "$actual_status"
    fi
}

create_mock sudo <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

create_mock apt-get <<'EOF'
#!/usr/bin/env bash

case "$*" in
    "--simulate autoremove")
        printf '%s\n' \
            "NOTE: This is only a simulation!" \
            "Remv apt-orphan [1.0]"
        ;;
    "clean")
        printf '%s\n' "apt-get clean"
        ;;
    "autoremove --assume-yes")
        printf '%s\n' "apt-get autoremove --assume-yes"
        ;;
    *)
        exit 1
        ;;
esac
EOF

create_mock apt <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

create_mock dnf <<'EOF'
#!/usr/bin/env bash

case "$*" in
    "repoquery --unneeded --installed --qf %{name}.%{arch}")
        printf '%s\n' "dnf-orphan.x86_64"
        ;;
    "clean packages")
        printf '%s\n' "dnf clean packages"
        ;;
    "autoremove --assumeyes")
        printf '%s\n' "dnf autoremove --assumeyes"
        ;;
    *)
        exit 1
        ;;
esac
EOF

create_mock pacman <<'EOF'
#!/usr/bin/env bash

case "$*" in
    "-Qtdq")
        printf '%s\n' "pacman-orphan-one" "pacman-orphan-two"
        ;;
    "-Rns --noconfirm pacman-orphan-one pacman-orphan-two")
        printf 'pacman %s\n' "$*"
        ;;
    *)
        exit 1
        ;;
esac
EOF

create_mock paccache <<'EOF'
#!/usr/bin/env bash
printf 'paccache %s\n' "$*"
EOF

create_mock checkupdates <<'EOF'
#!/usr/bin/env bash
exit 2
EOF

create_mock zypper <<'EOF'
#!/usr/bin/env bash

case "$*" in
    "--no-refresh --no-color packages --unneeded")
        printf '%s\n' \
            "Loading repository data..." \
            "Reading installed packages..." \
            "S | Repository | Name | Version | Arch" \
            "--+------------+------+---------+-----" \
            "i | repo-main | zypper-orphan | 1.0 | x86_64"
        ;;
    "--non-interactive clean")
        printf '%s\n' "zypper --non-interactive clean"
        ;;
    "--non-interactive remove --clean-deps zypper-orphan")
        printf 'zypper %s\n' "$*"
        ;;
    *)
        exit 1
        ;;
esac
EOF

create_mock du <<'EOF'
#!/usr/bin/env bash
printf '42M\t%s\n' "${2:-${1:-unknown}}"
EOF

create_mock journalctl <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" == "--disk-usage" ]]; then
    printf '%s\n' \
        "Archived and active journals take up 128.0M in the file system."
    exit 0
fi

exit 1
EOF

# shellcheck source=../src/core/common.sh
source "${PROJECT_ROOT}/src/core/common.sh"

# shellcheck source=../src/core/cleanup_metrics.sh
source "${PROJECT_ROOT}/src/core/cleanup_metrics.sh"

# shellcheck source=../src/core/package_manager.sh
source "${PROJECT_ROOT}/src/core/package_manager.sh"

# shellcheck source=../src/modules/cleanup/cleanup.sh
source "${PROJECT_ROOT}/src/modules/cleanup/cleanup.sh"

printf '%s\n\n' "Running cleanup tests..."

PKG_MANAGER="apt"

assert_equals \
    "Package cache directory can be overridden" \
    "$MOCK_CACHE" \
    "$(get_package_cache_directory)"

assert_equals \
    "Package cache size is detected" \
    "42M" \
    "$(get_package_cache_size)"

assert_output_contains \
    "Journal disk usage is reported" \
    "128.0M" \
    get_journal_disk_usage

assert_equals \
    "APT lists packages selected by autoremove" \
    "apt-orphan" \
    "$(list_unneeded_packages)"

assert_output_contains \
    "APT package cache cleanup uses apt-get clean" \
    "apt-get clean" \
    clean_package_cache

assert_output_contains \
    "APT package cleanup uses autoremove" \
    "apt-get autoremove --assume-yes" \
    remove_unneeded_packages

PKG_MANAGER="dnf"

assert_equals \
    "DNF lists unneeded installed packages" \
    "dnf-orphan.x86_64" \
    "$(list_unneeded_packages)"

assert_output_contains \
    "DNF cleans downloaded packages only" \
    "dnf clean packages" \
    clean_package_cache

assert_output_contains \
    "DNF package cleanup uses autoremove" \
    "dnf autoremove --assumeyes" \
    remove_unneeded_packages

PKG_MANAGER="pacman"

assert_output_contains \
    "Pacman lists orphaned dependencies" \
    "pacman-orphan-two" \
    list_unneeded_packages

assert_output_contains \
    "Pacman cache cleanup keeps two versions" \
    "paccache -rk2" \
    clean_package_cache

assert_output_contains \
    "Pacman removes the collected orphan list" \
    "pacman -Rns --noconfirm pacman-orphan-one pacman-orphan-two" \
    remove_unneeded_packages

PKG_MANAGER="zypper"

assert_equals \
    "Zypper parses unneeded package names" \
    "zypper-orphan" \
    "$(list_unneeded_packages)"

assert_output_contains \
    "Zypper cleans downloaded package caches" \
    "zypper --non-interactive clean" \
    clean_package_cache

assert_output_contains \
    "Zypper removes collected packages with clean dependencies" \
    "zypper --non-interactive remove --clean-deps zypper-orphan" \
    remove_unneeded_packages

PKG_MANAGER="unknown"

assert_exit_status \
    "Unknown package manager cleanup returns status 2" \
    2 \
    clean_package_cache

assert_output_contains \
    "Cleanup report CLI displays the package cache size" \
    "Package cache size:    42M" \
    "$LAC_SCRIPT" \
    --cleanup-report

assert_output_contains \
    "Cleanup report CLI remains read-only and lists candidates" \
    "Unneeded packages:     1" \
    "$LAC_SCRIPT" \
    -c

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
