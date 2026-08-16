#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"
BUILD_ROOT="${TEST_TMP_DIR}/LinuxAdminCenter"
EXTRACT_ROOT="${TEST_TMP_DIR}/extract"
TEST_HOME="${TEST_TMP_DIR}/home"
BUILD_LOG="${TEST_TMP_DIR}/build.log"

trap 'rm -rf "$TEST_TMP_DIR"' EXIT

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

assert_true() {
    local description="$1"
    shift

    if "$@"; then
        pass_test "$description"
    else
        fail_test "$description"
    fi
}

assert_false() {
    local description="$1"
    shift

    if "$@"; then
        fail_test "$description"
    else
        pass_test "$description"
    fi
}

assert_contains() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected substring: %s\n' "$expected"
        printf '       Actual output:      %s\n' "$actual"
    fi
}

printf '%s\n\n' "Running Debian package build validation..."

for tool in dpkg-buildpackage dpkg-deb dh; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Error: required packaging tool is missing: %s\n' "$tool" >&2
        exit 2
    fi
done

mkdir -p "$BUILD_ROOT" "$EXTRACT_ROOT" "$TEST_HOME"
cp -a "${PROJECT_ROOT}/." "$BUILD_ROOT/"

if ! (
    cd "$BUILD_ROOT"
    DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage --build=binary --no-sign
) >"$BUILD_LOG" 2>&1; then
    printf '%s\n' "Debian package build failed:" >&2
    cat "$BUILD_LOG" >&2
    exit 1
fi

PACKAGE_FILE="$(
    find "$TEST_TMP_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'linux-admin-center_*_all.deb' \
        -print \
        -quit
)"

if [[ -z "$PACKAGE_FILE" ]]; then
    printf '%s\n' "Error: Debian package build produced no .deb file." >&2
    cat "$BUILD_LOG" >&2
    exit 1
fi

assert_equals \
    "Package name is linux-admin-center" \
    "linux-admin-center" \
    "$(dpkg-deb -f "$PACKAGE_FILE" Package)"

assert_equals \
    "Package is architecture independent" \
    "all" \
    "$(dpkg-deb -f "$PACKAGE_FILE" Architecture)"

assert_equals \
    "Package uses the 1.2.0-alpha2 Debian version" \
    "1.2.0~alpha2-1" \
    "$(dpkg-deb -f "$PACKAGE_FILE" Version)"

dpkg-deb -x "$PACKAGE_FILE" "$EXTRACT_ROOT"

assert_true \
    "Package installs the lac command" \
    test -x "${EXTRACT_ROOT}/usr/bin/lac"

assert_false \
    "Package does not install the manual lac-uninstall command" \
    test -e "${EXTRACT_ROOT}/usr/bin/lac-uninstall"

assert_false \
    "Package does not install the manual uninstaller payload" \
    test -e "${EXTRACT_ROOT}/usr/share/linux-admin-center/uninstall.sh"

assert_equals \
    "Package marks the installation as Debian-managed" \
    "deb" \
    "$(<"${EXTRACT_ROOT}/usr/share/linux-admin-center/package-manager")"

assert_true \
    "Package installs the runtime" \
    test -x "${EXTRACT_ROOT}/usr/lib/linux-admin-center/lac.sh"

assert_true \
    "Package installs Debian copyright metadata" \
    test -s "${EXTRACT_ROOT}/usr/share/doc/linux-admin-center/copyright"

assert_false \
    "Package avoids a duplicate upstream LICENSE file" \
    test -e "${EXTRACT_ROOT}/usr/share/doc/linux-admin-center/LICENSE"

version_output="$(
    HOME="$TEST_HOME" \
    LAC_SYSTEM_CONFIG="${TEST_TMP_DIR}/system.conf" \
    "${EXTRACT_ROOT}/usr/bin/lac" --version
)"

assert_equals \
    "Extracted package runs the 1.2.0-alpha2 LAC version" \
    "Linux Admin Center 1.2.0-alpha2 (Release Automation)" \
    "$version_output"

self_check_output="$(
    HOME="$TEST_HOME" \
    LAC_SYSTEM_CONFIG="${TEST_TMP_DIR}/system.conf" \
    "${EXTRACT_ROOT}/usr/bin/lac" --self-check
)"

assert_contains \
    "Packaged Self Check identifies Debian installation" \
    "Installation:           debian-package" \
    "$self_check_output"

assert_contains \
    "Packaged Self Check is healthy" \
    "Status:                 healthy" \
    "$self_check_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
