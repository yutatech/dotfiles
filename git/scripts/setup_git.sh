#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../../setup_utils/utils.sh

COMMANDS="git"
check_and_install_commands "$COMMANDS"

$SCRIPT_DIR/download_completion.sh
$SCRIPT_DIR/create_config_symlink.sh