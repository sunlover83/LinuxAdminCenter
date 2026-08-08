#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

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

assert_success() {
    local description="$1"
    shift

    if "$@"; then
        pass_test "$description"
    else
        fail_test "$description"
    fi
}

assert_failure() {
    local description="$1"
    shift

    if "$@"; then
        fail_test "$description"
    else
        pass_test "$description"
    fi
}

# shellcheck source=../src/core/common.sh
source "${PROJECT_ROOT}/src/core/common.sh"

printf '%s\n\n' "Running common runtime tests..."

assert_success \
    "Bash 4.3 meets the minimum" \
    is_bash_version_supported 4 3

assert_success \
    "Newer Bash versions meet the minimum" \
    is_bash_version_supported 5 2

assert_failure \
    "Bash 4.2 is below the minimum" \
    is_bash_version_supported 4 2

assert_failure \
    "Invalid Bash version values are rejected" \
    is_bash_version_supported invalid 3

assert_equals \
    "Debian maps directly to APT" \
    "apt" \
    "$(get_package_manager_for_distribution debian '')"

assert_equals \
    "Fedora maps directly to DNF" \
    "dnf" \
    "$(get_package_manager_for_distribution fedora '')"

assert_equals \
    "Arch maps directly to Pacman" \
    "pacman" \
    "$(get_package_manager_for_distribution arch '')"

assert_equals \
    "openSUSE maps directly to Zypper" \
    "zypper" \
    "$(get_package_manager_for_distribution opensuse-tumbleweed '')"

assert_equals \
    "Debian-derived distributions map through ID_LIKE" \
    "apt" \
    "$(get_package_manager_for_distribution example-linux 'ubuntu debian')"

assert_equals \
    "RHEL-derived distributions map through ID_LIKE" \
    "dnf" \
    "$(get_package_manager_for_distribution example-enterprise 'rhel fedora')"

assert_equals \
    "Arch-derived distributions map through ID_LIKE" \
    "pacman" \
    "$(get_package_manager_for_distribution example-rolling 'arch')"

assert_equals \
    "SUSE-derived distributions map through ID_LIKE" \
    "zypper" \
    "$(get_package_manager_for_distribution example-suse 'suse opensuse')"

assert_equals \
    "Unknown distribution families remain unsupported" \
    "unknown" \
    "$(get_package_manager_for_distribution example-linux 'independent')"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
