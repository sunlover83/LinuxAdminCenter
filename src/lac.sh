#!/usr/bin/env bash

###############################################################################
# Linux Admin Center (LAC)
# Version : 0.1.0-alpha
# Codename: Foundation
###############################################################################

set -euo pipefail

readonly LAC_VERSION="0.1.0-alpha"
readonly LAC_CODENAME="Foundation"

main() {
    clear

    echo "========================================="
    echo "      Linux Admin Center (LAC)"
    echo "========================================="
    echo
    echo "Version : ${LAC_VERSION}"
    echo "Codename: ${LAC_CODENAME}"
    echo
    echo "Project initialized successfully."
}

main "$@"
