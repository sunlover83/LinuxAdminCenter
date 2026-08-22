#!/usr/bin/env bash

is_storage_tool_available() {
    local tool_name="$1"

    command -v "$tool_name" >/dev/null 2>&1
}

is_storage_filesystem_excluded() {
    local filesystem_type="${1,,}"

    case "$filesystem_type" in
        ""|proc|sysfs|devtmpfs|devpts|tmpfs|ramfs|cgroup|cgroup2|pstore|\
            securityfs|debugfs|tracefs|configfs|fusectl|mqueue|hugetlbfs|\
            rpc_pipefs|autofs|binfmt_misc|efivarfs|nsfs|bpf|selinuxfs|\
            fuse.portal|fuse.gvfsd-fuse|fuse.sshfs|fuse.rclone|squashfs|\
            iso9660|udf|erofs|romfs|cramfs)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_storage_percentage() {
    local percentage="${1%%%}"

    if [[ "$percentage" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$percentage"
    else
        printf '%s\n' "not-applicable"
    fi
}

get_storage_filesystem_records() {
    local storage_output=""
    local source
    local filesystem_type
    local total_kib
    local used_kib
    local available_kib
    local capacity_percentage
    local inode_total
    local inode_used
    local inode_available
    local inode_percentage
    local mountpoint
    local line_number=0
    local -a records=()

    if ! is_storage_tool_available df; then
        printf '%s\n' "unavailable"
        return
    fi

    if ! storage_output="$(
        LC_ALL=C df \
            --local \
            --block-size=1024 \
            --output=source,fstype,size,used,avail,pcent,itotal,iused,iavail,ipcent,target \
            2>/dev/null
    )"; then
        printf '%s\n' "unknown"
        return
    fi

    while read -r \
        source \
        filesystem_type \
        total_kib \
        used_kib \
        available_kib \
        capacity_percentage \
        inode_total \
        inode_used \
        inode_available \
        inode_percentage \
        mountpoint; do

        line_number=$((line_number + 1))

        if (( line_number == 1 )); then
            continue
        fi

        if [[ -z "$source" || -z "$mountpoint" ]] ||
            is_storage_filesystem_excluded "$filesystem_type"; then
            continue
        fi

        capacity_percentage="$(
            normalize_storage_percentage "$capacity_percentage"
        )"

        if [[ ! "$total_kib" =~ ^[0-9]+$ ]] ||
            [[ ! "$used_kib" =~ ^[0-9]+$ ]] ||
            [[ ! "$available_kib" =~ ^-?[0-9]+$ ]] ||
            [[ "$capacity_percentage" == "not-applicable" ]] ||
            (( total_kib == 0 )); then
            continue
        fi

        inode_percentage="$(
            normalize_storage_percentage "$inode_percentage"
        )"

        if [[ ! "$inode_total" =~ ^[0-9]+$ ]] ||
            [[ ! "$inode_used" =~ ^[0-9]+$ ]] ||
            [[ ! "$inode_available" =~ ^[0-9]+$ ]] ||
            [[ "$inode_percentage" == "not-applicable" ]] ||
            (( inode_total == 0 )); then
            inode_total="not-applicable"
            inode_used="not-applicable"
            inode_available="not-applicable"
            inode_percentage="not-applicable"
        fi

        records+=(
            "${source}|${filesystem_type}|${total_kib}|${used_kib}|${available_kib}|${capacity_percentage}|${inode_total}|${inode_used}|${inode_available}|${inode_percentage}|${mountpoint}"
        )
    done <<< "$storage_output"

    if (( ${#records[@]} == 0 )); then
        printf '%s\n' "none"
        return
    fi

    printf '%s\n' "${records[@]}" |
        LC_ALL=C sort -t '|' -k11,11 -k1,1
}
