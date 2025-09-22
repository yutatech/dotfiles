#!/bin/sh
# gh (GitHub CLI) configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $REPO_DIR/setup_utils/utils.sh

SOURCE_FILES=""

CHECK_FILES=""

SYMLINKS=""

COMMANDS="gh"

is_configure_completed "$SOURCE_FILES $CHECK_FILES" "$SYMLINKS" "$COMMANDS"
CONFIG_COMPETED=$?

if [ $CONFIG_COMPETED -eq 1 ]; then
    # 設定が完了していない場合は、コマンドを上書き
    source $SCRIPT_DIR/source/overwrite_command.sh
fi
