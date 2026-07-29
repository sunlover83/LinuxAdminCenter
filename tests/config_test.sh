#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEST_TMP_DIR="$(mktemp -d)"
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

assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Actual:   %s\n' "$actual"
    fi
}

assert_output_contains() {
    local description="$1"
    local expected="$2"
    local output
    local output_file

    shift 2

    output_file="$(mktemp "${TEST_TMP_DIR}/output.XXXXXX")"

    if "$@" >"$output_file" 2>&1; then
        :
    else
        :
    fi

    output="$(<"$output_file")"
    rm -f "$output_file"

    if [[ "$output" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Output:   %s\n' "$output"
    fi
}

reset_configuration() {
    LAC_DEBUG="false"
    LAC_SYSTEM_CONFIG="${TEST_TMP_DIR}/missing-system.conf"
    LAC_USER_CONFIG="${TEST_TMP_DIR}/missing-user.conf"
}

# shellcheck source=../src/core/config.sh
source "${PROJECT_ROOT}/src/core/config.sh"

printf '%s\n\n' "Running configuration tests..."

reset_configuration
load_configuration

assert_equals \
    "Missing configuration files keep default values" \
    "false" \
    "$LAC_DEBUG"

system_config="${TEST_TMP_DIR}/system.conf"

cat > "$system_config" <<'EOF'
DEBUG=true
EOF

reset_configuration
LAC_SYSTEM_CONFIG="$system_config"
load_configuration

assert_equals \
    "System configuration enables debug mode" \
    "true" \
    "$LAC_DEBUG"

user_config="${TEST_TMP_DIR}/user.conf"

cat > "$user_config" <<'EOF'
DEBUG=false
EOF

reset_configuration
LAC_SYSTEM_CONFIG="$system_config"
LAC_USER_CONFIG="$user_config"
load_configuration

assert_equals \
    "User configuration overrides system configuration" \
    "false" \
    "$LAC_DEBUG"

whitespace_config="${TEST_TMP_DIR}/whitespace.conf"

cat > "$whitespace_config" <<'EOF'
# Comment line

   DEBUG   =   true
EOF

reset_configuration
LAC_USER_CONFIG="$whitespace_config"
load_configuration

assert_equals \
    "Whitespace and comments are handled correctly" \
    "true" \
    "$LAC_DEBUG"

invalid_config="${TEST_TMP_DIR}/invalid.conf"

cat > "$invalid_config" <<'EOF'
DEBUG=invalid
EOF

reset_configuration
LAC_USER_CONFIG="$invalid_config"

assert_output_contains \
    "Invalid debug values produce a warning" \
    "DEBUG must be 'true' or 'false'" \
    load_configuration

assert_equals \
    "Invalid debug values fall back to false" \
    "false" \
    "$LAC_DEBUG"

unknown_config="${TEST_TMP_DIR}/unknown.conf"

cat > "$unknown_config" <<'EOF'
UNKNOWN_OPTION=true
DEBUG=true
EOF

reset_configuration
LAC_USER_CONFIG="$unknown_config"

assert_output_contains \
    "Unknown options produce a warning" \
    "Unknown configuration option: UNKNOWN_OPTION" \
    load_configuration

assert_equals \
    "Valid options are still loaded after unknown options" \
    "true" \
    "$LAC_DEBUG"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
