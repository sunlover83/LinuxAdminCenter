#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
WORKFLOW="${PROJECT_ROOT}/.github/workflows/release.yml"

[[ -f "$WORKFLOW" ]] || {
    printf '%s\n' "[FAIL] Release workflow is missing." >&2
    exit 1
}

workflow_content="$(cat "$WORKFLOW")"

for expected in \
    'contents: read' \
    'contents: write' \
    'persist-credentials: false' \
    'Verify tag points at current main' \
    "gh api \"repos/\${GITHUB_REPOSITORY}/commits/main\" --jq .sha" \
    'validate_release_metadata.sh' \
    'debian_package_lifecycle.sh' \
    'debian_package_lint.sh' \
    'SHA256SUMS' \
    'generate_release_notes.sh' \
    '--verify-tag' \
    '--prerelease --latest=false'; do
    if [[ "$workflow_content" != *"$expected"* ]]; then
        printf '[FAIL] Release workflow is missing safety invariant: %s\n' "$expected" >&2
        exit 1
    fi
done

printf '%s\n' "Release workflow safety-invariant test passed."
