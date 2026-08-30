#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
DIST_DIR="${PROJECT_ROOT}/dist"

section() {
    printf '\n'
    printf '%s\n' "============================================================"
    printf '%s\n' "$1"
    printf '%s\n' "============================================================"
    printf '\n'
}

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit "${2:-1}"
}

require_tool() {
    local tool="$1"

    command -v "$tool" >/dev/null 2>&1 ||
        fail "required tool is missing: ${tool}" 2
}

section "Linux Admin Center - Local Test"

printf 'Project:      %s\n' "$PROJECT_ROOT"
printf 'Architecture: %s\n' "$(uname -m)"
printf 'Kernel:       %s\n' "$(uname -r)"

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    printf 'Distribution: %s\n' "${PRETTY_NAME:-unknown}"
fi

section "Checking required tools"

for tool in \
    bash \
    docker \
    dpkg-buildpackage \
    dpkg-deb \
    dh \
    lintian \
    shellcheck; do
    require_tool "$tool"
    printf '[PASS] %s\n' "$tool"
done

if ! docker info >/dev/null 2>&1; then
    fail "Docker is installed but cannot be accessed. Check that the Docker service is running and your user belongs to the docker group."
fi

printf '[PASS] Docker daemon is accessible\n'

cd "$PROJECT_ROOT"

section "Running complete test suite"

bash tests/run_tests.sh

section "Validating Debian package build"

bash tests/debian_package_build.sh

section "Running Lintian validation"

bash tests/debian_package_lint.sh

section "Running Debian package lifecycle validation"

bash tests/debian_package_lifecycle.sh

section "Running ShellCheck"

shellcheck \
    install.sh \
    uninstall.sh \
    debian/preinst \
    scripts/*.sh \
    src/lac.sh \
    src/core/*.sh \
    src/modules/*/*.sh \
    tests/*.sh

printf '%s\n' "ShellCheck passed."

section "Building final Debian package"

rm -rf "$DIST_DIR"

bash scripts/build_debian_package.sh dist

PACKAGE_FILE="$(
    find "$DIST_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'linux-admin-center_*_all.deb' \
        -print \
        -quit
)"

[[ -n "$PACKAGE_FILE" ]] ||
    fail "No Debian package was created in ${DIST_DIR}."

section "Package information"

dpkg-deb -f "$PACKAGE_FILE" \
    Package \
    Version \
    Architecture

printf '\nPackage file:\n%s\n' "$PACKAGE_FILE"

section "Local test completed successfully"

printf '%s\n' "All tests and validations passed."
