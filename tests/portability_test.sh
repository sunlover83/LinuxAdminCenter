#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

printf '%s\n\n' "Running portability checks..."

printf '%s\n' "Checking Bash syntax..."

bash -n \
    "${PROJECT_ROOT}/install.sh" \
    "${PROJECT_ROOT}/uninstall.sh" \
    "${PROJECT_ROOT}/src/lac.sh" \
    "${PROJECT_ROOT}"/src/core/*.sh \
    "${PROJECT_ROOT}"/src/modules/*/*.sh \
    "${PROJECT_ROOT}"/tests/*.sh

printf '%s\n' "Checking active distribution mapping..."

# shellcheck source=../src/core/common.sh
source "${PROJECT_ROOT}/src/core/common.sh"
# shellcheck source=../src/core/package_manager.sh
source "${PROJECT_ROOT}/src/core/package_manager.sh"

detect_distribution

if [[ "$PKG_MANAGER" == "unknown" ]]; then
    printf 'Distribution %s did not map to a supported package manager.\n' \
        "$DISTRO_ID" >&2
    exit 1
fi

if ! is_package_manager_supported; then
    printf 'Mapped package manager %s is not available on distribution %s.\n' \
        "$PKG_MANAGER" \
        "$DISTRO_ID" >&2
    exit 1
fi

printf 'Detected %s with package manager %s.\n' \
    "$DISTRO_ID" \
    "$PKG_MANAGER"

printf '%s\n\n' "Running distribution-independent test subset..."

portable_tests=(
    common_test.sh
    config_test.sh
    installation_test.sh
    network_diagnostics_metrics_test.sh
    package_manager_test.sh
    self_check_test.sh
)

for test_file in "${portable_tests[@]}"; do
    printf 'Running %s\n' "$test_file"
    bash "${SCRIPT_DIR}/${test_file}"
    echo
done

printf '%s\n' "All portability checks passed."
