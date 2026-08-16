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
    'prepare_release_assets.sh' \
    'SHA256SUMS' \
    'generate_release_notes.sh' \
    '--verify-tag' \
    '--prerelease --latest=false' \
    "--jq '.assets[].name'" \
    "grep -Fxq \"\$expected_asset\""; do
    if [[ "$workflow_content" != *"$expected"* ]]; then
        printf '[FAIL] Release workflow is missing safety invariant: %s\n' "$expected" >&2
        exit 1
    fi
done

if [[ "$workflow_content" == *'sha256sum linux-admin-center_*_all.deb > SHA256SUMS'* ]]; then
    printf '%s\n' "[FAIL] Release workflow creates SHA256SUMS before asset-name normalization." >&2
    exit 1
fi

printf '%s\n' "Release workflow safety-invariant test passed."
