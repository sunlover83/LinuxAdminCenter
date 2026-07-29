#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"

mkdir -p "$MOCK_BIN"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${PATH}"

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

assert_command_succeeds() {
    local description="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        pass_test "$description"
    else
        fail_test "$description"
    fi
}

assert_command_fails() {
    local description="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        fail_test "$description"
    else
        pass_test "$description"
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
printf 'apt-get %s\n' "$*"
EOF

create_mock apt <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" == "list" && "${2:-}" == "--upgradable" ]]; then
    printf '%s\n' \
        "Listing..." \
        "pkg-one/jammy 2.0 amd64 [upgradable from: 1.0]"
    exit 0
fi

exit 1
EOF

create_mock dnf <<'EOF'
#!/usr/bin/env bash

case "${1:-}" in
    makecache)
        printf 'dnf %s\n' "$*"
        exit 0
        ;;
    check-update)
        printf '%s\n' "pkg-two.x86_64 2.0 repository"
        exit 100
        ;;
    upgrade)
        printf 'dnf %s\n' "$*"
        exit 0
        ;;
esac

exit 1
EOF

create_mock checkupdates <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "pkg-three 1.0 -> 2.0"
exit 0
EOF

create_mock pacman <<'EOF'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*"
EOF

create_mock zypper <<'EOF'
#!/usr/bin/env bash

case "$*" in
    "--non-interactive refresh")
        printf 'zypper %s\n' "$*"
        ;;
    "--no-refresh --no-color list-updates")
        printf '%s\n' \
            "v | repository | pkg-four | 1.0 | 2.0 | x86_64"
        ;;
    "--non-interactive update")
        printf 'zypper %s\n' "$*"
        ;;
    "--non-interactive dist-upgrade")
        printf 'zypper %s\n' "$*"
        ;;
    *)
        exit 1
        ;;
esac
EOF

# shellcheck source=../src/core/package_manager.sh
source "${PROJECT_ROOT}/src/core/package_manager.sh"

printf '%s\n\n' "Running package manager tests..."

PKG_MANAGER="apt"

assert_command_succeeds \
    "APT is detected as supported" \
    is_package_manager_supported

assert_output_contains \
    "APT refresh uses apt-get update" \
    "apt-get update" \
    refresh_package_information

assert_output_contains \
    "APT lists available updates" \
    "pkg-one/jammy" \
    list_available_updates

assert_output_contains \
    "APT installation uses apt-get upgrade" \
    "apt-get upgrade --assume-yes" \
    install_available_updates

PKG_MANAGER="dnf"

assert_command_succeeds \
    "DNF is detected as supported" \
    is_package_manager_supported

assert_output_contains \
    "DNF refreshes its package cache" \
    "dnf makecache --refresh" \
    refresh_package_information

assert_output_contains \
    "DNF status 100 is treated as success" \
    "pkg-two.x86_64" \
    list_available_updates

assert_output_contains \
    "DNF installation uses dnf upgrade" \
    "dnf upgrade --assumeyes" \
    install_available_updates

PKG_MANAGER="pacman"

assert_command_succeeds \
    "Pacman is detected as supported" \
    is_package_manager_supported

assert_command_succeeds \
    "Pacman refresh step succeeds safely" \
    refresh_package_information

assert_output_contains \
    "Pacman lists updates with checkupdates" \
    "pkg-three" \
    list_available_updates

assert_output_contains \
    "Pacman installation performs a full upgrade" \
    "pacman -Syu --noconfirm" \
    install_available_updates

create_mock checkupdates <<'EOF'
#!/usr/bin/env bash
exit 2
EOF

assert_command_succeeds \
    "Checkupdates status 2 means no updates" \
    list_available_updates

PKG_MANAGER="zypper"

assert_command_succeeds \
    "Zypper is detected as supported" \
    is_package_manager_supported

assert_output_contains \
    "Zypper refreshes repositories" \
    "zypper --non-interactive refresh" \
    refresh_package_information

assert_output_contains \
    "Zypper lists available updates" \
    "pkg-four 1.0 -> 2.0 (x86_64)" \
    list_available_updates

DISTRO_ID="opensuse-leap"

assert_output_contains \
    "openSUSE Leap uses zypper update" \
    "zypper --non-interactive update" \
    install_available_updates

DISTRO_ID="opensuse-tumbleweed"

assert_output_contains \
    "openSUSE Tumbleweed uses dist-upgrade" \
    "zypper --non-interactive dist-upgrade" \
    install_available_updates

PKG_MANAGER="unknown"

assert_command_fails \
    "Unknown package managers are rejected" \
    is_package_manager_supported

assert_exit_status \
    "Unknown package manager refresh returns status 2" \
    2 \
    refresh_package_information

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
