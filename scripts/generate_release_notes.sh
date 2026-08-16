#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="${LAC_PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd -P)}"
RELEASE_TAG="${1:-${GITHUB_REF_NAME:-}}"
OUTPUT_FILE="${2:-${PROJECT_ROOT}/release-notes.md}"

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit "${2:-1}"
}

[[ -n "$RELEASE_TAG" ]] || fail "release tag is required." 2

"${SCRIPT_DIR}/validate_release_metadata.sh" "$RELEASE_TAG" >/dev/null

release_version="${RELEASE_TAG#v}"
runtime_file="${PROJECT_ROOT}/src/core/common.sh"
debian_changelog="${PROJECT_ROOT}/debian/changelog"
project_changelog="${PROJECT_ROOT}/CHANGELOG.md"

codename="$(sed -n 's/^readonly LAC_CODENAME="\([^"]*\)"$/\1/p' "$runtime_file" | head -n 1)"
debian_version="$(sed -n '1s/^[^(]*(\([^)]*\)).*/\1/p' "$debian_changelog")"
release_debian_version="${debian_version//\~/-}"
package_name="linux-admin-center_${release_debian_version}_all.deb"

section_file="$(mktemp)"
trap 'rm -f "$section_file"' EXIT

if ! awk -v version="$release_version" '
    BEGIN {
        target = "## [" version "] - "
        found = 0
    }
    index($0, target) == 1 {
        found = 1
        next
    }
    found && /^## \[/ {
        exit
    }
    found {
        print
    }
    END {
        if (!found) {
            exit 42
        }
    }
' "$project_changelog" > "$section_file"; then
    fail "could not extract release notes for ${release_version} from CHANGELOG.md"
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

{
    printf '# Linux Admin Center %s (%s)\n\n' "$release_version" "$codename"
    cat "$section_file"
    printf '\n## Release assets\n\n'
    printf '%s\n' "- \`${package_name}\`"
    printf '%s\n' "- \`SHA256SUMS\`"
} > "$OUTPUT_FILE"

printf 'Release notes created: %s\n' "$OUTPUT_FILE"
