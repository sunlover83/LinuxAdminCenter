#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="${LAC_PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd -P)}"
RELEASE_TAG="${1:-${GITHUB_REF_NAME:-}}"

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit "${2:-1}"
}

validate_release_tag() {
    local tag="$1"
    local major
    local minor
    local patch
    local prerelease
    local component
    local identifier
    local -a prerelease_identifiers=()

    if [[ ! "$tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$ ]]; then
        fail "release tag must match supported SemVer syntax vMAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH-PRERELEASE: ${tag}" 2
    fi

    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    patch="${BASH_REMATCH[3]}"
    prerelease="${BASH_REMATCH[5]:-}"

    for component in "$major" "$minor" "$patch"; do
        if [[ "$component" =~ ^0[0-9]+$ ]]; then
            fail "release tag is not valid SemVer: numeric identifiers must not contain leading zeroes: ${tag}" 2
        fi
    done

    if [[ -n "$prerelease" ]]; then
        IFS='.' read -r -a prerelease_identifiers <<< "$prerelease"

        for identifier in "${prerelease_identifiers[@]}"; do
            if [[ "$identifier" =~ ^0[0-9]+$ ]]; then
                fail "release tag is not valid SemVer: numeric prerelease identifiers must not contain leading zeroes: ${tag}" 2
            fi
        done
    fi
}

[[ -n "$RELEASE_TAG" ]] || fail "release tag is required." 2
validate_release_tag "$RELEASE_TAG"

release_version="${RELEASE_TAG#v}"
runtime_file="${PROJECT_ROOT}/src/core/common.sh"
debian_changelog="${PROJECT_ROOT}/debian/changelog"
project_changelog="${PROJECT_ROOT}/CHANGELOG.md"
manpage="${PROJECT_ROOT}/debian/lac.1"

for path in "$runtime_file" "$debian_changelog" "$project_changelog" "$manpage"; do
    [[ -f "$path" ]] || fail "required release metadata file is missing: ${path}"
done

runtime_version="$(sed -n 's/^readonly LAC_VERSION="\([^"]*\)"$/\1/p' "$runtime_file" | head -n 1)"
codename="$(sed -n 's/^readonly LAC_CODENAME="\([^"]*\)"$/\1/p' "$runtime_file" | head -n 1)"
debian_version="$(sed -n '1s/^[^(]*(\([^)]*\)).*/\1/p' "$debian_changelog")"

[[ -n "$runtime_version" ]] || fail "could not read LAC_VERSION from src/core/common.sh"
[[ -n "$codename" ]] || fail "could not read LAC_CODENAME from src/core/common.sh"
[[ -n "$debian_version" ]] || fail "could not read the Debian version from debian/changelog"

if [[ "$release_version" == *-* ]]; then
    base_version="${release_version%%-*}"
    prerelease_version="${release_version#*-}"
    expected_debian_version="${base_version}~${prerelease_version}-1"
    release_kind="prerelease"
else
    expected_debian_version="${release_version}-1"
    release_kind="stable"
fi

[[ "$runtime_version" == "$release_version" ]] ||
    fail "runtime version ${runtime_version} does not match release tag ${release_version}"

[[ "$debian_version" == "$expected_debian_version" ]] ||
    fail "Debian version ${debian_version} does not match expected release version ${expected_debian_version}"

grep -Fq "## [${release_version}] - " "$project_changelog" ||
    fail "CHANGELOG.md has no dated section for ${release_version}"

grep -Fq "Linux Admin Center ${release_version}" "$manpage" ||
    fail "debian/lac.1 does not describe Linux Admin Center ${release_version}"

printf '%s\n' "Release metadata valid."
printf '  Tag:            %s\n' "$RELEASE_TAG"
printf '  Version:        %s\n' "$release_version"
printf '  Codename:       %s\n' "$codename"
printf '  Debian version: %s\n' "$debian_version"
printf '  Release kind:   %s\n' "$release_kind"
