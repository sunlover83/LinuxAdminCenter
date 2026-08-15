#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"
BUILD_ROOT="${TEST_TMP_DIR}/LinuxAdminCenter"
BUILD_LOG="${TEST_TMP_DIR}/build.log"

trap 'rm -rf "$TEST_TMP_DIR"' EXIT

printf '%s\n\n' "Running Lintian validation..."

for tool in dpkg-buildpackage dh lintian; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Error: required Lintian validation tool is missing: %s\n' "$tool" >&2
        exit 2
    fi
done

mkdir -p "$BUILD_ROOT"
cp -a "${PROJECT_ROOT}/." "$BUILD_ROOT/"

if ! (
    cd "$BUILD_ROOT"
    DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage --build=binary --no-sign
) >"$BUILD_LOG" 2>&1; then
    printf '%s\n' "Debian package build failed before Lintian validation:" >&2
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
    printf '%s\n' "Error: Lintian validation build produced no .deb file." >&2
    cat "$BUILD_LOG" >&2
    exit 1
fi

lintian \
    --profile debian \
    --display-info \
    --fail-on error,warning \
    "$PACKAGE_FILE"

printf '%s\n' "Lintian validation passed without error- or warning-level findings."
