#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
DIST_DIR="${1:-${PROJECT_ROOT}/dist}"

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit "${2:-1}"
}

[[ -d "$DIST_DIR" ]] || fail "release asset directory does not exist: ${DIST_DIR}" 2

mapfile -t package_files < <(
    find "$DIST_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'linux-admin-center_*_all.deb' \
        -print \
        | LC_ALL=C sort
)

if (( ${#package_files[@]} != 1 )); then
    fail "expected exactly one Debian package in ${DIST_DIR}, found ${#package_files[@]}."
fi

package_file="${package_files[0]}"
package_basename="${package_file##*/}"
debian_version="${package_basename#linux-admin-center_}"
debian_version="${debian_version%_all.deb}"

[[ -n "$debian_version" && "$debian_version" != "$package_basename" ]] || \
    fail "could not determine Debian version from package filename: ${package_basename}"

release_version="${debian_version//\~/-}"
release_basename="linux-admin-center_${release_version}_all.deb"
release_file="${DIST_DIR}/${release_basename}"

if [[ "$package_file" != "$release_file" ]]; then
    [[ ! -e "$release_file" ]] || fail "release asset already exists: ${release_file}"
    mv -- "$package_file" "$release_file"
fi

(
    cd "$DIST_DIR"
    sha256sum "$release_basename" > SHA256SUMS
)

printf 'Release package prepared: %s\n' "$release_file"
printf 'Release checksum created: %s\n' "${DIST_DIR}/SHA256SUMS"
cat "${DIST_DIR}/SHA256SUMS"
