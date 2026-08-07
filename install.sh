#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX="${PREFIX:-/usr/local}"
DESTDIR="${DESTDIR:-}"
APP_DIR_NAME="linux-admin-center"

usage() {
    cat <<'EOF'
Linux Admin Center installer

Usage:
  sudo ./install.sh [--prefix PATH]

Options:
  -h, --help       Show this help message
  --prefix PATH    Installation prefix (default: /usr/local)

Packaging and test environments may set DESTDIR. Example:
  DESTDIR=/tmp/package-root ./install.sh --prefix /usr
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
        fail "System installation requires root privileges. Run sudo ./install.sh."
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

install_runtime() {
    safe_remove_tree "$RUNTIME_DIR" "/lib/${APP_DIR_NAME}"

    mkdir -p "$RUNTIME_DIR"
    cp -R "${PROJECT_ROOT}/src/." "$RUNTIME_DIR/"

    find "$RUNTIME_DIR" -type d -exec chmod 0755 {} +
    find "$RUNTIME_DIR" -type f -exec chmod 0644 {} +
    chmod 0755 "${RUNTIME_DIR}/lac.sh"
}

install_launchers() {
    mkdir -p "$BIN_DIR"

    cat > "$LAC_BIN" <<'EOF_LAC'
#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX_DIR="$(cd "${BIN_DIR}/.." && pwd -P)"

exec "${PREFIX_DIR}/lib/linux-admin-center/lac.sh" "$@"
EOF_LAC

    cat > "$UNINSTALL_BIN" <<'EOF_UNINSTALL'
#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX_DIR="$(cd "${BIN_DIR}/.." && pwd -P)"

PREFIX="$PREFIX_DIR" exec \
    "${PREFIX_DIR}/share/linux-admin-center/uninstall.sh" "$@"
EOF_UNINSTALL

    chmod 0755 "$LAC_BIN" "$UNINSTALL_BIN"
}

install_shared_files() {
    safe_remove_tree "$SHARE_DIR" "/share/${APP_DIR_NAME}"
    safe_remove_tree "$DOC_DIR" "/share/doc/${APP_DIR_NAME}"

    mkdir -p "$SHARE_DIR" "$DOC_DIR"

    cp "${PROJECT_ROOT}/config/lac.conf.example" \
        "${SHARE_DIR}/lac.conf.example"
    cp "${PROJECT_ROOT}/uninstall.sh" \
        "${SHARE_DIR}/uninstall.sh"

    chmod 0644 "${SHARE_DIR}/lac.conf.example"
    chmod 0755 "${SHARE_DIR}/uninstall.sh"

    cp "${PROJECT_ROOT}/README.md" "$DOC_DIR/"
    cp "${PROJECT_ROOT}/CHANGELOG.md" "$DOC_DIR/"
    cp "${PROJECT_ROOT}/docs/"*.md "$DOC_DIR/"
    chmod 0644 "$DOC_DIR"/*.md
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

install_runtime
install_shared_files
install_launchers

printf '%s\n' "Linux Admin Center installed successfully."
printf '  Command:        %s\n' "${PREFIX}/bin/lac"
printf '  Uninstaller:    %s\n' "${PREFIX}/bin/lac-uninstall"
printf '  Runtime:        %s\n' "${PREFIX}/lib/${APP_DIR_NAME}"
printf '  Documentation:  %s\n' "${PREFIX}/share/doc/${APP_DIR_NAME}"

if [[ -n "$DESTDIR" ]]; then
    printf '  Staging root:   %s\n' "$DESTDIR"
fi
