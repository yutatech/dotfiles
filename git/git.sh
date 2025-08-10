#!/bin/sh
# git configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $REPO_DIR/setup_utils/utils.sh

SOURCE_FILES="$SCRIPT_DIR/source/git_env.sh"

CHECK_FILES=""

SYMLINKS="
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

COMMANDS="git"

is_configure_completed "$SOURCE_FILES $CHECK_FILES" "$SYMLINKS" "$COMMANDS"
CONFIG_COMPETED=$?

if [ $CONFIG_COMPETED -eq 1 ]; then
    # 設定が完了していない場合は、コマンドを上書き
    source $SCRIPT_DIR/source/overwrite_command.sh
else
    source_all "$SOURCE_FILES"
fi

source $REPO_DIR/setup_utils/unset_utils.sh