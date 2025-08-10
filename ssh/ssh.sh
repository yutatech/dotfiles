#!/bin/sh
# ssh configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $REPO_DIR/setup_utils/utils.sh

SOURCE_FILES="$SCRIPT_DIR/source/ssh_env.sh"

CHECK_FILES="$HOME/.ssh/config"

SYMLINKS=""

COMMANDS=""

source_all "$SOURCE_FILES"
