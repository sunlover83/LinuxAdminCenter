#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

runtime_version="$(
    sed -n 's/^readonly LAC_VERSION="\([^"]*\)"$/\1/p' \
        "${PROJECT_ROOT}/src/core/common.sh" | head -n 1
)"

if [[ -z "$runtime_version" ]]; then
    printf '%s\n' "[FAIL] Could not read the current LAC runtime version." >&2
    exit 1
fi

"${PROJECT_ROOT}/scripts/validate_release_metadata.sh" \
    "v${runtime_version}" >/dev/null

printf 'Current release metadata is consistent for v%s.\n' "$runtime_version"
