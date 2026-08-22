#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"
RUNTIME_ROOT="${TEST_TMP_DIR}/usr/local/lib/linux-admin-center"
PREFIX_ROOT="${TEST_TMP_DIR}/usr/local"
PACKAGE_MARKER="${PREFIX_ROOT}/share/linux-admin-center/package-manager"

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

assert_success() {
    local description="$1"
    shift

    if "$@"; then
        pass_test "$description"
    else
        fail_test "$description"
    fi
}

# shellcheck source=../src/core/common.sh
source "${PROJECT_ROOT}/src/core/common.sh"
# shellcheck source=../src/core/config.sh
source "${PROJECT_ROOT}/src/core/config.sh"
# shellcheck source=../src/core/self_check_metrics.sh
source "${PROJECT_ROOT}/src/core/self_check_metrics.sh"

printf '%s\n\n' "Running self-check metrics tests..."

assert_equals \
    "Current Bash runtime is reported as compatible" \
    "compatible" \
    "$(get_bash_runtime_status | awk '{ print $1 }')"

assert_equals \
    "System-wide runtime paths are detected" \
    "system-wide" \
    "$(get_lac_installation_type "$RUNTIME_ROOT")"

assert_equals \
    "Repository runtime paths are detected" \
    "repository" \
    "$(get_lac_installation_type "${TEST_TMP_DIR}/project/src")"

assert_equals \
    "Custom runtime paths are detected" \
    "custom" \
    "$(get_lac_installation_type "${TEST_TMP_DIR}/runtime")"

required_files=(
    lac.sh
    core/common.sh
    core/config.sh
    core/system_metrics.sh
    core/storage_metrics.sh
    core/network_metrics.sh
    core/network_diagnostics_metrics.sh
    core/cleanup_metrics.sh
    core/hardware_metrics.sh
    core/gaming_metrics.sh
    core/gaming_diagnostics_metrics.sh
    core/service_metrics.sh
    core/self_check_metrics.sh
    core/cli.sh
    core/package_manager.sh
    core/ui.sh
    modules/update/update.sh
    modules/cleanup/cleanup.sh
    modules/network_info/network_info.sh
    modules/system_info/system_info.sh
    modules/storage_analysis/storage_analysis.sh
    modules/hardware_diagnostics/hardware_diagnostics.sh
    modules/network_diagnostics/network_diagnostics.sh
    modules/gaming_readiness/gaming_readiness.sh
    modules/gaming_diagnostics/gaming_diagnostics.sh
    modules/service_health/service_health.sh
    modules/self_check/self_check.sh
)

for relative_path in "${required_files[@]}"; do
    mkdir -p "${RUNTIME_ROOT}/$(dirname "$relative_path")"
    : > "${RUNTIME_ROOT}/${relative_path}"
done

assert_equals \
    "Complete runtime trees are detected" \
    "complete" \
    "$(get_lac_runtime_files_status "$RUNTIME_ROOT")"

rm "${RUNTIME_ROOT}/core/cli.sh"

assert_equals \
    "Missing runtime files are counted" \
    "missing (1)" \
    "$(get_lac_runtime_files_status "$RUNTIME_ROOT")"

: > "${RUNTIME_ROOT}/core/cli.sh"
mkdir -p "${PREFIX_ROOT}/bin"
: > "${PREFIX_ROOT}/bin/lac"
: > "${PREFIX_ROOT}/bin/lac-uninstall"
chmod +x "${PREFIX_ROOT}/bin/lac" "${PREFIX_ROOT}/bin/lac-uninstall"

assert_equals \
    "Complete system-wide launchers are detected" \
    "available" \
    "$(get_lac_launcher_status "$RUNTIME_ROOT")"

rm "${PREFIX_ROOT}/bin/lac-uninstall"

assert_equals \
    "Missing system-wide launchers are detected" \
    "incomplete" \
    "$(get_lac_launcher_status "$RUNTIME_ROOT")"

mkdir -p "$(dirname "$PACKAGE_MARKER")"
printf '%s\n' "deb" > "$PACKAGE_MARKER"

assert_equals \
    "Debian package installations are detected from the package marker" \
    "debian-package" \
    "$(get_lac_installation_type "$RUNTIME_ROOT")"

assert_equals \
    "Debian package installations require only the lac launcher" \
    "available" \
    "$(get_lac_launcher_status "$RUNTIME_ROOT")"

rm "${PREFIX_ROOT}/bin/lac"

assert_equals \
    "Missing lac launcher fails Debian package launcher detection" \
    "incomplete" \
    "$(get_lac_launcher_status "$RUNTIME_ROOT")"

: > "${PREFIX_ROOT}/bin/lac"
chmod +x "${PREFIX_ROOT}/bin/lac"
rm "$PACKAGE_MARKER"

assert_equals \
    "Repository launchers are not required" \
    "not applicable" \
    "$(get_lac_launcher_status "${TEST_TMP_DIR}/project/src")"

CONFIG_FILE="${TEST_TMP_DIR}/lac.conf"

assert_equals \
    "Missing configuration uses defaults" \
    "defaults" \
    "$(get_lac_config_file_status "$CONFIG_FILE")"

printf '%s\n' "DEBUG=false" > "$CONFIG_FILE"

assert_equals \
    "Readable configuration files are available" \
    "available" \
    "$(get_lac_config_file_status "$CONFIG_FILE")"

assert_equals \
    "Missing user-home context uses configuration defaults" \
    "defaults" \
    "$(
        unset LAC_USER_CONFIG XDG_CONFIG_HOME HOME
        get_lac_user_config_status
    )"

assert_equals \
    "Required tools are available on the test runner" \
    "complete" \
    "$(get_lac_required_tools_status)"

optional_records="$(get_lac_optional_tool_records)"

if grep -q '^lsblk|' <<< "$optional_records" &&
    grep -q '^systemctl|' <<< "$optional_records"; then
    pass_test "Self-check lists hardware and service diagnostic tools"
else
    fail_test "Self-check lists hardware and service diagnostic tools"
fi

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
