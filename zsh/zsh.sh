#!/bin/sh
# git configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../setup_utils/utils.sh

SOURCE_FILES=""

CHECK_FILES="
    $SCRIPT_DIR/completion/zsh-autosuggestions/zsh-autosuggestions.zsh
    $SCRIPT_DIR/completion/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
"

SYMLINKS=""

COMMAND="zsh"

is_configure_completed "$SOURCE_FILES $CHECK_FILES" "$SYMLINKS" "$COMMAND"
CONFIG_COMPETED=$?

if [ $CONFIG_COMPETED -eq 1 ]; then
    # 設定が完了していない場合は、コマンドを上書き
    source $SCRIPT_DIR/source/overwrite_command.sh
else
    source_all "$SOURCE_FILES"
fi

if [ -n "${ZSH_VERSION}" ]; then
  source $SCRIPT_DIR/source/zsh_env.zsh
  source $SCRIPT_DIR/completion/zsh-autosuggestions/zsh-autosuggestions.zsh
  source $SCRIPT_DIR/completion/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

source $SCRIPT_DIR/../setup_utils/unset_utils.sh