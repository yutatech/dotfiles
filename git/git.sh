#!/bin/sh
# git configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../setup_utils/utils.sh

SOURCE_FILES=""

CHECK_FILES="
    $HOME/.gitconfig
    $HOME/.gitignore_global
"

if [ -n "${BASH_VERSION}" ]; then
    # bashの場合
    SOURCE_FILES="
        $SOURCE_FILES
        $SCRIPT_DIR/completion/git-completion.bash
        $SCRIPT_DIR/completion/git-prompt.sh
    "
fi

COMMAND="git"

is_configure_completed "$SOURCE_FILES" "$CHECK_FILES" "$COMMAND"
CONFIG_COMPETED=$?

if [ $CONFIG_COMPETED -eq 1 ]; then
    # gitの設定が完了していない場合は、gitコマンドを上書き
    source $SCRIPT_DIR/source/overwrite_git_command.sh
else
    source_all "$SOURCE_FILES"
    source $SCRIPT_DIR/source/git_env.sh
fi

source $SCRIPT_DIR/../setup_utils/unset_utils.sh
source $SCRIPT_DIR/../setup_utils/unset_vars.sh