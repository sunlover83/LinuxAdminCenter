#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=core/common.sh
source "${SCRIPT_DIR}/core/common.sh"

# shellcheck source=core/config.sh
source "${SCRIPT_DIR}/core/config.sh"

# shellcheck source=core/system_metrics.sh
source "${SCRIPT_DIR}/core/system_metrics.sh"

# shellcheck source=core/network_metrics.sh
source "${SCRIPT_DIR}/core/network_metrics.sh"

# shellcheck source=core/cleanup_metrics.sh
source "${SCRIPT_DIR}/core/cleanup_metrics.sh"

# shellcheck source=core/hardware_metrics.sh
source "${SCRIPT_DIR}/core/hardware_metrics.sh"

# shellcheck source=core/cli.sh
source "${SCRIPT_DIR}/core/cli.sh"

# shellcheck source=core/package_manager.sh
source "${SCRIPT_DIR}/core/package_manager.sh"

# shellcheck source=core/ui.sh
source "${SCRIPT_DIR}/core/ui.sh"

# shellcheck source=modules/update/update.sh
source "${SCRIPT_DIR}/modules/update/update.sh"

# shellcheck source=modules/cleanup/cleanup.sh
source "${SCRIPT_DIR}/modules/cleanup/cleanup.sh"

# shellcheck source=modules/network_info/network_info.sh
source "${SCRIPT_DIR}/modules/network_info/network_info.sh"

# shellcheck source=modules/system_info/system_info.sh
source "${SCRIPT_DIR}/modules/system_info/system_info.sh"

# shellcheck source=modules/hardware_diagnostics/hardware_diagnostics.sh
source "${SCRIPT_DIR}/modules/hardware_diagnostics/hardware_diagnostics.sh"

load_configuration

if (( $# > 0 )); then
    handle_cli_arguments "$@" || exit $?
    exit 0
fi

main
