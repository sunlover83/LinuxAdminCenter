#!/usr/bin/env bash

###############################################################################
# Linux Admin Center (LAC)
# Version : 0.1.0-alpha
# Codename: Foundation
###############################################################################

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=core/common.sh
source "${SCRIPT_DIR}/core/common.sh"

# shellcheck source=core/package_manager.sh
source "${SCRIPT_DIR}/core/package_manager.sh"

# shellcheck source=core/ui.sh
source "${SCRIPT_DIR}/core/ui.sh"

# shellcheck source=modules/update/update.sh
source "${SCRIPT_DIR}/modules/update/update.sh"

# shellcheck source=modules/system_info/system_info.sh
source "${SCRIPT_DIR}/modules/system_info/system_info.sh"

main "$@"
