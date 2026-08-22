#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

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
    local actual="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        pass_test "$description"
    else
        fail_test "$description"
        printf '       Expected: %s\n' "$expected"
        printf '       Actual:   %s\n' "$actual"
    fi
}

# shellcheck source=../src/core/storage_metrics.sh
source "${PROJECT_ROOT}/src/core/storage_metrics.sh"

# shellcheck source=../src/modules/storage_analysis/storage_analysis.sh
source "${PROJECT_ROOT}/src/modules/storage_analysis/storage_analysis.sh"

MOCK_STORAGE_RECORDS=""

get_storage_filesystem_records() {
    printf '%s\n' "$MOCK_STORAGE_RECORDS"
}

printf '%s\n\n' "Running storage analysis tests..."

assert_equals \
    "Values below 80 percent are healthy" \
    "healthy" \
    "$(get_storage_usage_status 79)"

assert_equals \
    "The 80 percent boundary is a warning" \
    "warning" \
    "$(get_storage_usage_status 80)"

assert_equals \
    "Values below 90 percent remain warnings" \
    "warning" \
    "$(get_storage_usage_status 89)"

assert_equals \
    "The 90 percent boundary is critical" \
    "critical" \
    "$(get_storage_usage_status 90)"

assert_equals \
    "Invalid usage values are incomplete" \
    "incomplete" \
    "$(get_storage_usage_status unknown)"

assert_equals \
    "Critical inode pressure makes a record critical" \
    "critical" \
    "$(get_storage_record_status 40 90)"

assert_equals \
    "Unavailable inode metrics do not reduce a healthy record" \
    "healthy" \
    "$(get_storage_record_status 40 not-applicable)"

assert_equals \
    "Warnings take precedence over incomplete secondary data" \
    "warning" \
    "$(get_storage_record_status 80 unknown)"

assert_equals \
    "KiB values are formatted as MiB" \
    "1.0 MiB" \
    "$(format_storage_kib 1024)"

assert_equals \
    "Large values are formatted as TiB" \
    "1.0 TiB" \
    "$(format_storage_kib 1073741824)"

assert_equals \
    "Negative available capacity remains visible" \
    "-1.0 MiB" \
    "$(format_storage_kib -1024)"

healthy_records='/dev/root|ext4|104857600|41943040|62914560|40|6553600|1310720|5242880|20|/'
warning_records="${healthy_records}"$'\n''/dev/data|xfs|209715200|167772160|41943040|80|104857600|62914560|41943040|60|/srv/data'
critical_records="${warning_records}"$'\n''/dev/archive|btrfs|524288000|471859200|52428800|90|not-applicable|not-applicable|not-applicable|not-applicable|/srv/archive'
incomplete_records='/dev/root|ext4|104857600|41943040|62914560|unknown|6553600|1310720|5242880|20|/'

assert_equals \
    "Healthy records produce a healthy summary" \
    "healthy" \
    "$(get_storage_analysis_summary "$healthy_records")"

assert_equals \
    "Warning records produce a warning summary" \
    "warning" \
    "$(get_storage_analysis_summary "$warning_records")"

assert_equals \
    "Critical records take precedence in the summary" \
    "critical" \
    "$(get_storage_analysis_summary "$critical_records")"

assert_equals \
    "Incomplete record data produces an incomplete summary" \
    "incomplete" \
    "$(get_storage_analysis_summary "$incomplete_records")"

assert_equals \
    "Unavailable collection data produces an incomplete summary" \
    "incomplete" \
    "$(get_storage_analysis_summary unavailable)"

MOCK_STORAGE_RECORDS="${healthy_records}"$'\n''/dev/efi|vfat|1048576|524288|524288|50|not-applicable|not-applicable|not-applicable|not-applicable|/boot/efi'$'\n''/dev/data|xfs|209715200|188743680|20971520|90|104857600|62914560|41943040|60|/srv/data'

analysis_output="$(print_storage_analysis)"

assert_output_contains \
    "The report displays warning and critical thresholds" \
    "Critical:    90%" \
    "$analysis_output"

assert_output_contains \
    "The report includes a status legend" \
    "Status meanings:" \
    "$analysis_output"

assert_output_contains \
    "The report explains healthy states" \
    "All evaluated capacity and inode values are below 80%." \
    "$analysis_output"

assert_output_contains \
    "The report explains warning states" \
    "At least one value is between 80% and 89%; none is critical." \
    "$analysis_output"

assert_output_contains \
    "The report explains critical states" \
    "At least one value is 90% or higher." \
    "$analysis_output"

assert_output_contains \
    "The report explains incomplete states" \
    "Available data is insufficient for a complete assessment." \
    "$analysis_output"

assert_output_contains \
    "The report displays filesystem mountpoints and types" \
    "/srv/data (xfs)" \
    "$analysis_output"

assert_output_contains \
    "The report formats capacity usage" \
    "180.0 GiB / 200.0 GiB (90% used, 20.0 GiB available)" \
    "$analysis_output"

assert_output_contains \
    "The report displays unsupported inode metrics explicitly" \
    "Inodes:      not applicable" \
    "$analysis_output"

assert_output_contains \
    "The report displays a critical overall assessment" \
    "Status:      critical" \
    "$analysis_output"

assert_output_contains \
    "The report explains critical assessments" \
    "At least one filesystem has reached a critical threshold." \
    "$analysis_output"

assert_output_contains \
    "Critical recommendations prioritize timely review" \
    "Act promptly and identify the metric on filesystems marked critical." \
    "$analysis_output"

assert_output_contains \
    "Critical recommendations require a backup before modifications" \
    "Back up important data before cleanup, resizing or storage expansion." \
    "$analysis_output"

assert_output_contains \
    "Critical recommendations distinguish capacity pressure" \
    "For capacity pressure, archive or remove only verified unnecessary data." \
    "$analysis_output"

assert_output_contains \
    "Critical recommendations distinguish inode pressure" \
    "For inode pressure, investigate directories containing many small files." \
    "$analysis_output"

assert_output_contains \
    "Critical recommendations start with a read-only cleanup report" \
    "Run lac --cleanup-report for a read-only review of cleanup candidates." \
    "$analysis_output"

MOCK_STORAGE_RECORDS="$warning_records"
warning_output="$(print_storage_analysis)"

assert_output_contains \
    "Warning recommendations identify the triggering metric" \
    "Review filesystems marked warning and identify the triggering metric." \
    "$warning_output"

assert_output_contains \
    "Warning recommendations include the read-only cleanup report" \
    "Run lac --cleanup-report for a read-only review of cleanup candidates." \
    "$warning_output"

MOCK_STORAGE_RECORDS='/dev/disk/by-label/data%7Carchive%252026|ext4|104857600|41943040|62914560|40|6553600|1310720|5242880|20|/srv/data%7Carchive%252026'
delimiter_output="$(print_storage_analysis)"

assert_output_contains \
    "The report restores delimiters in filesystem mountpoints" \
    "/srv/data|archive%2026 (ext4)" \
    "$delimiter_output"

assert_output_contains \
    "The report restores delimiters in filesystem sources" \
    "/dev/disk/by-label/data|archive%2026" \
    "$delimiter_output"

assert_output_contains \
    "Encoded record fields preserve a healthy assessment" \
    "Status:      healthy" \
    "$delimiter_output"

assert_output_contains \
    "Healthy recommendations require no immediate action" \
    "No immediate action is required; continue monitoring." \
    "$delimiter_output"

MOCK_STORAGE_RECORDS="unknown"
unknown_output="$(print_storage_analysis)"

assert_output_contains \
    "Collection failures are displayed conservatively" \
    "unknown (filesystem data could not be read)" \
    "$unknown_output"

assert_output_contains \
    "Collection failures produce an incomplete assessment" \
    "Status:      incomplete" \
    "$unknown_output"

assert_output_contains \
    "Incomplete recommendations explain diagnostic checks" \
    "Check df availability, filesystem access and expected mount state." \
    "$unknown_output"

assert_output_contains \
    "Incomplete recommendations are not presented as healthy" \
    "Do not treat an incomplete assessment as healthy." \
    "$unknown_output"

printf '\n%s passed, %s failed.\n' "$passed" "$failed"

if (( failed > 0 )); then
    exit 1
fi
