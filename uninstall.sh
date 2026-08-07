#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
DESTDIR="${DESTDIR:-}"
APP_DIR_NAME="linux-admin-center"

usage() {
    cat <<'EOF'
Linux Admin Center uninstaller

Usage:
  sudo ./uninstall.sh [--prefix PATH]

Options:
  -h, --help       Show this help message
  --prefix PATH    Installation prefix (default: /usr/local)

The uninstaller removes only installed application files. It does not remove
/etc/lac or user configuration under ~/.config/lac.
EOF
}

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit "${2:-1}"
}

parse_arguments() {
    while (( $# > 0 )); do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --prefix)
                (( $# >= 2 )) || fail "--prefix requires a path." 2
                PREFIX="$2"
                shift 2
                ;;
            --prefix=*)
                PREFIX="${1#*=}"
                shift
                ;;
            *)
                fail "Unknown option: $1" 2
                ;;
        esac
    done
}

validate_paths() {
    PREFIX="${PREFIX%/}"
    DESTDIR="${DESTDIR%/}"

    [[ -n "$PREFIX" && "$PREFIX" == /* ]] ||
        fail "PREFIX must be an absolute path." 2

    [[ "$PREFIX" != "/" ]] ||
        fail "PREFIX=/ is not supported. Use /usr or /usr/local." 2

    if [[ -n "$DESTDIR" && "$DESTDIR" != /* ]]; then
        fail "DESTDIR must be an absolute path when set." 2
    fi
}

require_privileges() {
    if [[ -z "$DESTDIR" && ${EUID:-$(id -u)} -ne 0 ]]; then
        fail "System removal requires root privileges. Run sudo lac-uninstall."
    fi
}

safe_remove_tree() {
    local path="$1"
    local expected_suffix="$2"

    case "$path" in
        *"$expected_suffix")
            rm -rf -- "$path"
            ;;
        *)
            fail "Refusing to remove unexpected path: $path" 2
            ;;
    esac
}

parse_arguments "$@"
validate_paths
require_privileges

BIN_DIR="${DESTDIR}${PREFIX}/bin"
RUNTIME_DIR="${DESTDIR}${PREFIX}/lib/${APP_DIR_NAME}"
SHARE_DIR="${DESTDIR}${PREFIX}/share/${APP_DIR_NAME}"
DOC_DIR="${DESTDIR}${PREFIX}/share/doc/${APP_DIR_NAME}"
LAC_BIN="${BIN_DIR}/lac"
UNINSTALL_BIN="${BIN_DIR}/lac-uninstall"

removed_anything="false"

if [[ -e "$LAC_BIN" || -L "$LAC_BIN" ]]; then
    rm -f -- "$LAC_BIN"
    removed_anything="true"
fi

if [[ -e "$UNINSTALL_BIN" || -L "$UNINSTALL_BIN" ]]; then
    rm -f -- "$UNINSTALL_BIN"
    removed_anything="true"
fi

if [[ -d "$RUNTIME_DIR" ]]; then
    safe_remove_tree "$RUNTIME_DIR" "/lib/${APP_DIR_NAME}"
    removed_anything="true"
fi

if [[ -d "$SHARE_DIR" ]]; then
    safe_remove_tree "$SHARE_DIR" "/share/${APP_DIR_NAME}"
    removed_anything="true"
fi

if [[ -d "$DOC_DIR" ]]; then
    safe_remove_tree "$DOC_DIR" "/share/doc/${APP_DIR_NAME}"
    removed_anything="true"
fi

if [[ "$removed_anything" == "true" ]]; then
    printf '%s\n' "Linux Admin Center was removed successfully."
else
    printf '%s\n' "Linux Admin Center is not installed under ${PREFIX}."
fi

printf '%s\n' "Configuration files were preserved."
printf '  System configuration: %s\n' "/etc/lac"
printf '%s\n' "  User configuration:   \$HOME/.config/lac"
