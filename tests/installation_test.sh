#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"
TEST_ROOT="${TEST_TMP_DIR}/root"
TEST_HOME="${TEST_TMP_DIR}/home"
PREFIX="/usr/local"

trap 'rm -rf "$TEST_TMP_DIR"' EXIT
mkdir -p "$TEST_ROOT" "$TEST_HOME"

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

printf '%s\n\n' "Running installation tests..."

install_output="$(
    DESTDIR="$TEST_ROOT" \
    PREFIX="$PREFIX" \
    bash "${PROJECT_ROOT}/install.sh"
)"

LAC_BIN="${TEST_ROOT}${PREFIX}/bin/lac"
UNINSTALL_BIN="${TEST_ROOT}${PREFIX}/bin/lac-uninstall"
RUNTIME_DIR="${TEST_ROOT}${PREFIX}/lib/linux-admin-center"
SHARE_DIR="${TEST_ROOT}${PREFIX}/share/linux-admin-center"
DOC_DIR="${TEST_ROOT}${PREFIX}/share/doc/linux-admin-center"
SYSTEM_CONFIG="${TEST_ROOT}/etc/lac/lac.conf"

assert_true \
    "Installer creates the lac command" \
    test -x "$LAC_BIN"

assert_true \
    "Installer creates the lac-uninstall command" \
    test -x "$UNINSTALL_BIN"

assert_true \
    "Installer creates an executable runtime entry point" \
    test -x "${RUNTIME_DIR}/lac.sh"

assert_true \
    "Installer copies core runtime files" \
    test -f "${RUNTIME_DIR}/core/common.sh"

assert_true \
    "Installer copies feature modules" \
    test -f "${RUNTIME_DIR}/modules/gaming_diagnostics/gaming_diagnostics.sh"

assert_true \
    "Installer copies the example configuration" \
    test -f "${SHARE_DIR}/lac.conf.example"

assert_true \
    "Installer copies the installed uninstaller" \
    test -x "${SHARE_DIR}/uninstall.sh"

assert_true \
    "Installer copies user documentation" \
    test -f "${DOC_DIR}/Benutzerhandbuch.md"

assert_true \
    "Installer reports the installed command" \
    grep -Fq "Command:        ${PREFIX}/bin/lac" <<< "$install_output"

expected_version="$(
    HOME="$TEST_HOME" \
    LAC_SYSTEM_CONFIG="${TEST_ROOT}/etc/lac/lac.conf" \
    "${PROJECT_ROOT}/src/lac.sh" --version
)"

installed_version="$(
    HOME="$TEST_HOME" \
    LAC_SYSTEM_CONFIG="${TEST_ROOT}/etc/lac/lac.conf" \
    "$LAC_BIN" --version
)"

assert_equals \
    "Installed launcher runs the installed application" \
    "$expected_version" \
    "$installed_version"

touch "${RUNTIME_DIR}/stale-runtime-file"

DESTDIR="$TEST_ROOT" \
PREFIX="$PREFIX" \
bash "${PROJECT_ROOT}/install.sh" >/dev/null

assert_false \
    "Reinstallation removes stale runtime files" \
    test -e "${RUNTIME_DIR}/stale-runtime-file"

mkdir -p "$(dirname "$SYSTEM_CONFIG")"
printf '%s\n' "DEBUG=true" > "$SYSTEM_CONFIG"

uninstall_output="$(
    DESTDIR="$TEST_ROOT" \
    PREFIX="$PREFIX" \
    bash "${PROJECT_ROOT}/uninstall.sh"
)"

assert_false \
    "Uninstaller removes the lac command" \
    test -e "$LAC_BIN"

assert_false \
    "Uninstaller removes the lac-uninstall command" \
    test -e "$UNINSTALL_BIN"

assert_false \
    "Uninstaller removes runtime files" \
    test -d "$RUNTIME_DIR"

assert_false \
    "Uninstaller removes shared application files" \
    test -d "$SHARE_DIR"

assert_false \
    "Uninstaller removes installed documentation" \
    test -d "$DOC_DIR"

assert_true \
    "Uninstaller preserves system configuration" \
    test -f "$SYSTEM_CONFIG"

assert_true \
    "Uninstaller reports preserved configuration" \
    grep -Fq "Configuration files were preserved." <<< "$uninstall_output"

second_uninstall_output="$(
    DESTDIR="$TEST_ROOT" \
    PREFIX="$PREFIX" \
    bash "${PROJECT_ROOT}/uninstall.sh"
)"

assert_true \
    "Repeated uninstall is safe" \
    grep -Fq "is not installed" <<< "$second_uninstall_output"

if DESTDIR="$TEST_ROOT" PREFIX="relative/path" \
    bash "${PROJECT_ROOT}/install.sh" >/dev/null 2>&1; then
    fail_test "Installer rejects relative prefixes"
else
    pass_test "Installer rejects relative prefixes"
fi

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
