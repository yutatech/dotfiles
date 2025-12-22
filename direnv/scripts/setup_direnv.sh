#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../../setup_utils/utils.sh

COMMANDS="direnv"
check_and_install_commands "$COMMANDS"
