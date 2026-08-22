#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"
BUILD_ROOT="${TEST_TMP_DIR}/LinuxAdminCenter"
BUILD_LOG="${TEST_TMP_DIR}/build.log"

trap 'rm -rf "$TEST_TMP_DIR"' EXIT

printf '%s\n\n' "Running Debian package lifecycle validation..."

for tool in dpkg-buildpackage dh docker; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Error: required lifecycle tool is missing: %s\n' "$tool" >&2
        exit 2
    fi
done

mkdir -p "$BUILD_ROOT"
cp -a "${PROJECT_ROOT}/." "$BUILD_ROOT/"

if ! (
    cd "$BUILD_ROOT"
    DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage --build=binary --no-sign
) >"$BUILD_LOG" 2>&1; then
    printf '%s\n' "Debian package build failed before lifecycle validation:" >&2
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
    printf '%s\n' "Error: lifecycle build produced no .deb file." >&2
    cat "$BUILD_LOG" >&2
    exit 1
fi

docker run --rm -i \
    --volume "${PACKAGE_FILE}:/tmp/linux-admin-center.deb:ro" \
    debian:stable-slim \
    /bin/bash <<'EOF_CONTAINER'
set -euo pipefail

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

pass() {
    printf '[PASS] %s\n' "$1"
}

export DEBIAN_FRONTEND=noninteractive

apt-get update >/dev/null

mkdir -p /usr/local/bin /usr/local/lib/linux-admin-center
for path in \
    /usr/local/bin/lac \
    /usr/local/bin/lac-uninstall \
    /usr/local/lib/linux-admin-center/lac.sh; do
    printf '%s\n' '#!/bin/sh' 'exit 0' > "$path"
    chmod 0755 "$path"
done

set +e
manual_install_output="$(apt-get install --yes /tmp/linux-admin-center.deb 2>&1)"
manual_install_status=$?
set -e

if (( manual_install_status == 0 )); then
    fail "Package installation must stop when a manual /usr/local LAC installation is present"
fi

if [[ "$manual_install_output" != *"A manual Linux Admin Center installation was detected under /usr/local."* ]]; then
    printf '%s\n' "$manual_install_output" >&2
    fail "Manual installation conflict must produce the migration guidance"
fi
pass "Manual /usr/local installation is detected and blocks package installation"

rm -f /usr/local/bin/lac /usr/local/bin/lac-uninstall
rm -rf /usr/local/lib/linux-admin-center

mkdir -p /etc/lac
printf '%s\n' 'DEBUG=true' > /etc/lac/lac.conf

apt-get install --yes /tmp/linux-admin-center.deb >/dev/null

if [[ "$(dpkg-query -W -f='${Status}' linux-admin-center)" != "install ok installed" ]]; then
    fail "Package must be registered as installed by dpkg"
fi
pass "Package installs successfully through apt"

if [[ "$(lac --version)" != "Linux Admin Center 1.3.0-alpha4 (Storage Analysis)" ]]; then
    fail "Installed package must expose the expected LAC version"
fi
pass "Installed lac command reports the packaged version"

self_check_output="$(lac --self-check)"
if [[ "$self_check_output" != *"Installation:           debian-package"* ]]; then
    printf '%s\n' "$self_check_output" >&2
    fail "Installed Self Check must identify a Debian package installation"
fi
if [[ "$self_check_output" != *"Status:                 healthy"* ]]; then
    printf '%s\n' "$self_check_output" >&2
    fail "Installed package Self Check must be healthy"
fi
pass "Installed package Self Check is healthy"

storage_output="$(lac --storage-analysis)"
if [[ "$storage_output" != *"Overall storage assessment:"* ]]; then
    printf '%s\n' "$storage_output" >&2
    fail "Installed package must run read-only storage analysis"
fi
pass "Installed package runs read-only storage analysis"

if [[ -e /usr/bin/lac-uninstall ]]; then
    fail "Package must not install lac-uninstall"
fi
pass "Package removal remains under apt/dpkg control"

apt-get install --reinstall --yes /tmp/linux-admin-center.deb >/dev/null

if [[ "$(lac --version)" != "Linux Admin Center 1.3.0-alpha4 (Storage Analysis)" ]]; then
    fail "Reinstalled package must remain executable"
fi
if [[ "$(cat /etc/lac/lac.conf)" != "DEBUG=true" ]]; then
    fail "Reinstallation must preserve existing system configuration"
fi
pass "Package reinstallation preserves configuration"

apt-get remove --yes linux-admin-center >/dev/null

if [[ -e /usr/bin/lac || -e /usr/lib/linux-admin-center || -e /usr/share/linux-admin-center ]]; then
    fail "Package removal must remove managed LAC files"
fi
pass "apt removal removes package-managed LAC files"

if [[ ! -f /etc/lac/lac.conf ]] || [[ "$(cat /etc/lac/lac.conf)" != "DEBUG=true" ]]; then
    fail "Package removal must preserve administrator configuration"
fi
pass "apt removal preserves administrator configuration"
EOF_CONTAINER

printf '%s\n' "Debian package lifecycle validation passed."
