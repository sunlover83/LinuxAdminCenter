#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAC_SCRIPT="${PROJECT_ROOT}/src/lac.sh"

TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"

mkdir -p "$MOCK_BIN"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export PATH="${MOCK_BIN}:${PATH}"

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

create_mock() {
    local command_name="$1"

    cat > "${MOCK_BIN}/${command_name}"
    chmod +x "${MOCK_BIN}/${command_name}"
}

assert_status_and_output() {
    local description="$1"
    local expected_status="$2"
    local expected_output="$3"
    local output
    local actual_status

    shift 3

    if output=$("$@" 2>&1); then
        actual_status=0
    else
        actual_status=$?
    fi

    if (( actual_status == expected_status )) &&
        [[ "$output" == *"$expected_output"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected status: %s\n' "$expected_status"
        printf '       Actual status:   %s\n' "$actual_status"
        printf '       Expected output: %s\n' "$expected_output"
        printf '       Output:          %s\n' "$output"
    fi
}

create_mock sudo <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

create_mock apt-get <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" == "update" ]]; then
    printf '%s\n' "Package information refreshed."
    exit 0
fi

exit 1
EOF

create_mock apt <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" == "list" && "${2:-}" == "--upgradable" ]]; then
    printf '%s\n' \
        "Listing..." \
        "pkg-one/jammy 2.0 amd64 [upgradable from: 1.0]"
    exit 0
fi

exit 1
EOF

printf '%s\n\n' "Running update CLI tests..."

assert_status_and_output \
    "Long update option reports available updates" \
    10 \
    "1 update(s) available." \
    "$LAC_SCRIPT" \
    --check-updates

assert_status_and_output \
    "Short update option reports available updates" \
    10 \
    "pkg-one/jammy" \
    "$LAC_SCRIPT" \
    -u

create_mock apt <<'EOF'
#!/usr/bin/env bash

if [[ "${1:-}" == "list" && "${2:-}" == "--upgradable" ]]; then
    printf '%s\n' "Listing..."
    exit 0
fi

exit 1
EOF

assert_status_and_output \
    "Update check reports an up-to-date system" \
    0 \
    "System is up to date." \
    "$LAC_SCRIPT" \
    --check-updates

create_mock apt <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

assert_status_and_output \
    "Update listing failures return status 1" \
    1 \
    "Available updates could not be determined." \
    "$LAC_SCRIPT" \
    --check-updates

create_mock apt-get <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

assert_status_and_output \
    "Refresh failures return status 1" \
    1 \
    "Package information could not be refreshed." \
    "$LAC_SCRIPT" \
    --check-updates

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
