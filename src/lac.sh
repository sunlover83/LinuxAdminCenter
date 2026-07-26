#!/usr/bin/env bash

###############################################################################
# Linux Admin Center (LAC)
# Version : 0.1.0-alpha
# Codename: Foundation
###############################################################################

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/core/common.sh"
source "${SCRIPT_DIR}/core/ui.sh"
source "${SCRIPT_DIR}/modules/update/update.sh"

main "$@"
