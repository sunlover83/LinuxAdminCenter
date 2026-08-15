#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
VALIDATOR="${PROJECT_ROOT}/scripts/validate_release_metadata.sh"
TEST_TMP_DIR="$(mktemp -d)"
FIXTURE_ROOT="${TEST_TMP_DIR}/fixture"

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

write_fixture() {
    local runtime_version="${1:-1.2.0-alpha1}"
    local debian_version="${2:-1.2.0~alpha1-1}"
    local changelog_version="${3:-1.2.0-alpha1}"
    local manpage_version="${4:-1.2.0-alpha1}"

    rm -rf "$FIXTURE_ROOT"
    mkdir -p "$FIXTURE_ROOT/src/core" "$FIXTURE_ROOT/debian"

    cat > "$FIXTURE_ROOT/src/core/common.sh" <<EOF_FIXTURE
readonly LAC_VERSION="${runtime_version}"
readonly LAC_CODENAME="Release Automation"
EOF_FIXTURE

    cat > "$FIXTURE_ROOT/debian/changelog" <<EOF_FIXTURE
linux-admin-center (${debian_version}) unstable; urgency=medium
EOF_FIXTURE

    cat > "$FIXTURE_ROOT/CHANGELOG.md" <<EOF_FIXTURE
# Changelog

## [${changelog_version}] - 2026-08-15

### Added

- Example release entry.

## [1.1.0] - 2026-08-15
EOF_FIXTURE

    printf '.TH LAC 1 "August 2026" "Linux Admin Center %s" "User Commands"\n' \
        "$manpage_version" > "$FIXTURE_ROOT/debian/lac.1"
}

assert_success() {
    local description="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        pass_test "$description"
    else
        fail_test "$description"
    fi
}

assert_failure_contains() {
    local description="$1"
    local expected="$2"
    shift 2
    local output

    if output=$("$@" 2>&1); then
        fail_test "$description"
        printf '       Expected failure containing: %s\n' "$expected"
        return
    fi

    if [[ "$output" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Output:   %s\n' "$output"
    fi
}

printf '%s\n\n' "Running release metadata tests..."

write_fixture
assert_success \
    "Matching prerelease metadata is accepted" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha1

assert_failure_contains \
    "Malformed release tags are rejected" \
    "supported SemVer syntax" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" release-1.2.0

assert_failure_contains \
    "Trailing prerelease separators are rejected" \
    "supported SemVer syntax" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha.

assert_failure_contains \
    "Empty prerelease identifiers are rejected" \
    "supported SemVer syntax" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha..1

assert_failure_contains \
    "Leading zeroes in core versions are rejected" \
    "leading zeroes" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v01.2.0

assert_failure_contains \
    "Leading zeroes in numeric prerelease identifiers are rejected" \
    "numeric prerelease identifiers" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha.01

write_fixture "1.2.0-alpha.1" "1.2.0~alpha.1-1" "1.2.0-alpha.1" "1.2.0-alpha.1"
assert_success \
    "Dotted prerelease metadata is accepted" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha.1

write_fixture "1.2.0-alpha2"
assert_failure_contains \
    "Runtime version must match the tag" \
    "runtime version" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha1

write_fixture "1.2.0-alpha1" "1.2.0~alpha2-1"
assert_failure_contains \
    "Debian prerelease version must match the tag" \
    "Debian version" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha1

write_fixture "1.2.0-alpha1" "1.2.0~alpha1-1" "1.2.0-alpha2"
assert_failure_contains \
    "Project changelog must contain the release section" \
    "CHANGELOG.md has no dated section" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha1

write_fixture "1.2.0-alpha1" "1.2.0~alpha1-1" "1.2.0-alpha1" "1.2.0-alpha2"
assert_failure_contains \
    "Manpage version must match the release" \
    "debian/lac.1 does not describe" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0-alpha1

write_fixture "1.2.0" "1.2.0-1" "1.2.0" "1.2.0"
assert_success \
    "Matching stable release metadata is accepted" \
    env LAC_PROJECT_ROOT="$FIXTURE_ROOT" "$VALIDATOR" v1.2.0

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
