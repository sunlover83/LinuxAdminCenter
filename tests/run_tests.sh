#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

shopt -s nullglob

test_files=("${SCRIPT_DIR}"/*_test.sh)

if (( ${#test_files[@]} == 0 )); then
    printf '%s\n' "No tests found."
    exit 1
fi

for test_file in "${test_files[@]}"; do
    printf 'Running %s\n' "$(basename "$test_file")"
    bash "$test_file"
    echo
done

printf '%s\n' "All tests passed."
