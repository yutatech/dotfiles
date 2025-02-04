#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../../setup_utils/utils.sh

COMMANDS="tmux"
check_and_install_commands "$COMMANDS"

$SCRIPT_DIR/download_tmux_completion.sh
$SCRIPT_DIR/create_config_symlink.sh

source $SCRIPT_DIR/../source/tpm_utils.sh
setup_tpm_if_needed