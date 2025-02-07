#!/bin/sh
# git configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../setup_utils/utils.sh

SOURCE_FILES=""

CHECK_FILES=""

SYMLINKS=""

if [[ "$OSTYPE" == "darwin"* ]]; then
  SYMLINKS="$SYMLINKS $HOME/Library/Application\ Support/Code/User/settings.json"

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  SYMLINKS="$SYMLINKS $HOME/.config/Code/User/settings.json"
fi

COMMANDS="code"

is_configure_completed "$SOURCE_FILES $CHECK_FILES" "$SYMLINKS" "$COMMANDS"
CONFIG_COMPETED=$?

if [ $CONFIG_COMPETED -eq 1 ]; then
    # 設定が完了していない場合は、コマンドを上書き
    source $SCRIPT_DIR/source/overwrite_command.sh
else
    source_all "$SOURCE_FILES"
fi

source $SCRIPT_DIR/../setup_utils/unset_utils.sh
