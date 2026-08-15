#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"
FIXTURE_ROOT="${TEST_TMP_DIR}/fixture"
OUTPUT_FILE="${TEST_TMP_DIR}/release-notes.md"

trap 'rm -rf "$TEST_TMP_DIR"' EXIT

mkdir -p "$FIXTURE_ROOT/src/core" "$FIXTURE_ROOT/debian" "$FIXTURE_ROOT/scripts"
cp "$PROJECT_ROOT/scripts/validate_release_metadata.sh" "$FIXTURE_ROOT/scripts/"
cp "$PROJECT_ROOT/scripts/generate_release_notes.sh" "$FIXTURE_ROOT/scripts/"
chmod +x "$FIXTURE_ROOT/scripts/"*.sh

cat > "$FIXTURE_ROOT/src/core/common.sh" <<'EOF_FIXTURE'
readonly LAC_VERSION="1.2.0-alpha1"
readonly LAC_CODENAME="Release Automation"
EOF_FIXTURE

cat > "$FIXTURE_ROOT/debian/changelog" <<'EOF_FIXTURE'
linux-admin-center (1.2.0~alpha1-1) unstable; urgency=medium
EOF_FIXTURE

cat > "$FIXTURE_ROOT/debian/lac.1" <<'EOF_FIXTURE'
.TH LAC 1 "August 2026" "Linux Admin Center 1.2.0-alpha1" "User Commands"
EOF_FIXTURE

cat > "$FIXTURE_ROOT/CHANGELOG.md" <<'EOF_FIXTURE'
# Changelog

## [Unreleased]

No changes yet.

## [1.2.0-alpha1] - 2026-08-15

### Added

- Automated release workflow.

### Security

- Existing tags are verified before release publication.

## [1.1.0] - 2026-08-15

### Added

- Previous release content that must not appear.
EOF_FIXTURE

LAC_PROJECT_ROOT="$FIXTURE_ROOT" \
    "$FIXTURE_ROOT/scripts/generate_release_notes.sh" \
    v1.2.0-alpha1 \
    "$OUTPUT_FILE" >/dev/null

output="$(cat "$OUTPUT_FILE")"

for expected in \
    "# Linux Admin Center 1.2.0-alpha1 (Release Automation)" \
    "Automated release workflow." \
    "Existing tags are verified before release publication." \
    'linux-admin-center_1.2.0~alpha1-1_all.deb' \
    'SHA256SUMS'; do
    if [[ "$output" != *"$expected"* ]]; then
        printf '[FAIL] Release notes are missing: %s\n' "$expected" >&2
        exit 1
    fi
done

if [[ "$output" == *"Previous release content"* ]]; then
    printf '%s\n' "[FAIL] Release notes include content from the previous release." >&2
    exit 1
fi

printf '%s\n' "Release notes generation test passed."
