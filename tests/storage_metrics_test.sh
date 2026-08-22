#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
TEST_TMP_DIR="$(mktemp -d)"
MOCK_BIN="${TEST_TMP_DIR}/bin"
MISSING_BIN="${TEST_TMP_DIR}/missing-bin"

mkdir -p "$MOCK_BIN" "$MISSING_BIN"
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

assert_success() {
    local description="$1"
    shift

    if "$@"; then
        pass_test "$description"
    else
        fail_test "$description"
    fi
}

assert_failure() {
    local description="$1"
    shift

    if "$@"; then
        fail_test "$description"
    else
        pass_test "$description"
    fi
}

cat > "${MOCK_BIN}/df" <<'EOF'
#!/usr/bin/env bash

if [[ "${LC_ALL:-}" != "C" ]]; then
    printf '%s\n' "df must run with LC_ALL=C" >&2
    exit 90
fi

expected_arguments=(
    --all
    --local
    --block-size=1024
    "--output=source,fstype,size,used,avail,pcent,itotal,iused,iavail,ipcent,target"
)
actual_arguments=("$@")

excluded_filesystem_types=(
    proc sysfs devtmpfs devpts tmpfs ramfs cgroup cgroup2 pstore
    securityfs debugfs tracefs configfs fusectl mqueue hugetlbfs
    rpc_pipefs autofs binfmt_misc efivarfs nsfs bpf selinuxfs
    fuse.portal fuse.gvfsd-fuse fuse.sshfs fuse.rclone squashfs
    iso9660 udf erofs romfs cramfs
)

for filesystem_type in "${excluded_filesystem_types[@]}"; do
    expected_arguments+=("--exclude-type=${filesystem_type}")
done

if (( $# != ${#expected_arguments[@]} )); then
    printf 'Unexpected df arguments: %s\n' "$*" >&2
    exit 91
fi

for argument_index in "${!expected_arguments[@]}"; do
    if [[ "${actual_arguments[argument_index]}" != \
        "${expected_arguments[argument_index]}" ]]; then
        printf 'Unexpected df arguments: %s\n' "$*" >&2
        exit 91
    fi
done

case "${MOCK_DF_MODE:-success}" in
    success)
        cat <<'OUTPUT'
Filesystem Type 1K-blocks Used Available Use% Inodes IUsed IFree IUse% Mounted on
/dev/mapper/vg-data xfs 209715200 167772160 41943040 80% 104857600 62914560 41943040 60% /srv/data
/dev/mapper/vg-data xfs 209715200 167772160 41943040 80% 104857600 62914560 41943040 60% /srv/data-bind
tmpfs tmpfs 8192000 1024 8190976 1% 1000000 100 999900 1% /run
/run/user/1000/doc fuse.portal 1048576 512 1048064 1% 1000 1 999 1% /run/user/1000/doc
/dev/mapper/vg-root ext4 104857600 81788928 23068672 78% 6553600 1376256 5177344 21% /
/dev/nvme0n1p1 vfat 1048576 524288 524288 50% 0 0 0 - /boot/efi
/dev/mapper/vg-archive btrfs 524288000 525312000 -1024000 101% - - - - /srv/archive data
proc proc 0 0 0 - 0 0 0 - /proc
/dev/loop0 squashfs 131072 131072 0 100% 0 0 0 - /snap/example
/dev/mapper/empty ext4 0 0 0 - 0 0 0 - /empty
OUTPUT
        ;;
    empty)
        cat <<'OUTPUT'
Filesystem Type 1K-blocks Used Available Use% Inodes IUsed IFree IUse% Mounted on
tmpfs tmpfs 8192000 1024 8190976 1% 1000000 100 999900 1% /run
/dev/loop0 squashfs 131072 131072 0 100% 0 0 0 - /snap/example
OUTPUT
        ;;
    delimiters)
        cat <<'OUTPUT'
Filesystem Type 1K-blocks Used Available Use% Inodes IUsed IFree IUse% Mounted on
/dev/disk/by-label/data|archive%2026 ext4 104857600 41943040 62914560 40% 6553600 1310720 5242880 20% /srv/data|archive%2026
OUTPUT
        ;;
    inaccessible_excluded_mount)
        cat <<'OUTPUT'
Filesystem Type 1K-blocks Used Available Use% Inodes IUsed IFree IUse% Mounted on
/dev/mapper/vg-root ext4 104857600 81788928 23068672 78% 6553600 1376256 5177344 21% /
OUTPUT

        if [[ "$*" != *"--exclude-type=fuse.portal"* ]]; then
            printf '%s\n' "/run/user/1000/doc: Operation not permitted" >&2
            exit 1
        fi
        ;;
    failure)
        exit 1
        ;;
    *)
        exit 2
        ;;
esac
EOF

chmod +x "${MOCK_BIN}/df"

# shellcheck source=../src/core/storage_metrics.sh
source "${PROJECT_ROOT}/src/core/storage_metrics.sh"

printf '%s\n\n' "Running storage metrics tests..."

assert_success \
    "Pseudo filesystems are excluded" \
    is_storage_filesystem_excluded \
    tmpfs

assert_success \
    "Read-only image filesystems are excluded" \
    is_storage_filesystem_excluded \
    squashfs

assert_failure \
    "Persistent filesystems remain eligible" \
    is_storage_filesystem_excluded \
    ext4

assert_equals \
    "Percentages are normalized" \
    "91" \
    "$(normalize_storage_percentage "91%")"

assert_equals \
    "Unsupported percentages are explicit" \
    "not-applicable" \
    "$(normalize_storage_percentage "-")"

assert_equals \
    "Storage record fields encode delimiters and escape markers" \
    "data%7Carchive%257C%2525" \
    "$(encode_storage_record_field "data|archive%7C%25")"

assert_equals \
    "Storage record fields decode delimiters and escape markers" \
    "data|archive%7C%25" \
    "$(decode_storage_record_field "data%7Carchive%257C%2525")"

expected_records="$({
    printf '%s\n' \
        '/dev/mapper/vg-root|ext4|104857600|81788928|23068672|78|6553600|1376256|5177344|21|/' \
        '/dev/nvme0n1p1|vfat|1048576|524288|524288|50|not-applicable|not-applicable|not-applicable|not-applicable|/boot/efi' \
        '/dev/mapper/vg-archive|btrfs|524288000|525312000|-1024000|101|not-applicable|not-applicable|not-applicable|not-applicable|/srv/archive data' \
        '/dev/mapper/vg-data|xfs|209715200|167772160|41943040|80|104857600|62914560|41943040|60|/srv/data' \
        '/dev/mapper/vg-data|xfs|209715200|167772160|41943040|80|104857600|62914560|41943040|60|/srv/data-bind'
})"

export MOCK_DF_MODE=success

assert_equals \
    "Persistent and duplicate mount records are normalized, filtered and sorted" \
    "$expected_records" \
    "$(get_storage_filesystem_records)"

export MOCK_DF_MODE=delimiters

assert_equals \
    "Record delimiters in filesystem names cannot shift metric fields" \
    "/dev/disk/by-label/data%7Carchive%252026|ext4|104857600|41943040|62914560|40|6553600|1310720|5242880|20|/srv/data%7Carchive%252026" \
    "$(get_storage_filesystem_records)"

export MOCK_DF_MODE=inaccessible_excluded_mount

assert_equals \
    "Excluded inaccessible mounts do not discard persistent records" \
    "/dev/mapper/vg-root|ext4|104857600|81788928|23068672|78|6553600|1376256|5177344|21|/" \
    "$(get_storage_filesystem_records)"

export MOCK_DF_MODE=empty

assert_equals \
    "An empty persistent filesystem set is explicit" \
    "none" \
    "$(get_storage_filesystem_records)"

export MOCK_DF_MODE=failure

assert_equals \
    "df failures are reported conservatively" \
    "unknown" \
    "$(get_storage_filesystem_records)"

assert_equals \
    "A missing df command is reported" \
    "unavailable" \
    "$(PATH="$MISSING_BIN" get_storage_filesystem_records)"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
