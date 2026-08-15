#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
OUTPUT_DIR="${1:-dist}"
BUILD_TMP_DIR="$(mktemp -d)"
BUILD_ROOT="${BUILD_TMP_DIR}/LinuxAdminCenter"
BUILD_LOG="${BUILD_TMP_DIR}/build.log"

trap 'rm -rf "$BUILD_TMP_DIR"' EXIT

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit "${2:-1}"
}

for tool in dpkg-buildpackage dh; do
    command -v "$tool" >/dev/null 2>&1 ||
        fail "required Debian packaging tool is missing: ${tool}" 2
done

if [[ "$OUTPUT_DIR" != /* ]]; then
    OUTPUT_DIR="${PROJECT_ROOT}/${OUTPUT_DIR}"
fi

mkdir -p "$BUILD_ROOT" "$OUTPUT_DIR"
cp -a "${PROJECT_ROOT}/." "$BUILD_ROOT/"
rm -rf "${BUILD_ROOT}/.git" "${BUILD_ROOT}/dist"

if ! (
    cd "$BUILD_ROOT"
    dpkg-buildpackage --build=binary --no-sign
) >"$BUILD_LOG" 2>&1; then
    cat "$BUILD_LOG" >&2
    fail "Debian package build failed."
fi

PACKAGE_FILE="$(
    find "$BUILD_TMP_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'linux-admin-center_*_all.deb' \
        -print \
        -quit
)"

[[ -n "$PACKAGE_FILE" ]] || fail "Debian package build produced no .deb file."

PACKAGE_NAME="$(basename "$PACKAGE_FILE")"
cp "$PACKAGE_FILE" "${OUTPUT_DIR}/${PACKAGE_NAME}"

printf 'Debian package created: %s\n' "${OUTPUT_DIR}/${PACKAGE_NAME}"
