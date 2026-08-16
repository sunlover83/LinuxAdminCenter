#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TEST_TMP_DIR"' EXIT

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

run_case() {
    local case_name="$1"
    local source_name="$2"
    local expected_name="$3"
    local case_dir="${TEST_TMP_DIR}/${case_name}"

    mkdir -p "$case_dir"
    printf '%s\n' "release asset fixture for ${case_name}" > "${case_dir}/${source_name}"

    bash "${PROJECT_ROOT}/scripts/prepare_release_assets.sh" "$case_dir" >/dev/null

    [[ -f "${case_dir}/${expected_name}" ]] || \
        fail "${case_name}: expected release package is missing"

    if [[ "$source_name" != "$expected_name" && -e "${case_dir}/${source_name}" ]]; then
        fail "${case_name}: source package name was not normalized"
    fi

    grep -Fq "  ${expected_name}" "${case_dir}/SHA256SUMS" || \
        fail "${case_name}: SHA256SUMS does not reference the published package name"

    if grep -Fq '~' "${case_dir}/SHA256SUMS"; then
        fail "${case_name}: SHA256SUMS still contains a GitHub-unsafe tilde"
    fi

    (
        cd "$case_dir"
        sha256sum --check SHA256SUMS >/dev/null
    ) || fail "${case_name}: SHA256SUMS verification failed"

    printf '[PASS] %s\n' "$case_name"
}

printf '%s\n\n' "Running release asset preparation tests..."

run_case \
    "Prerelease package name is GitHub-safe" \
    "linux-admin-center_1.2.0~alpha1-1_all.deb" \
    "linux-admin-center_1.2.0-alpha1-1_all.deb"

run_case \
    "Stable package name remains unchanged" \
    "linux-admin-center_1.2.0-1_all.deb" \
    "linux-admin-center_1.2.0-1_all.deb"

printf '%s\n' "Release asset preparation tests passed."
