#!/bin/sh
# git configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../setup_utils/utils.sh

# 自作サブコマンド
export PATH="$SCRIPT_DIR/cmd:$PATH"

SOURCE_FILES=""

CHECK_FILES=""

SYMLINKS="
    $HOME/.gitconfig
    $HOME/.gitignore_global
"

if [ -n "${ZSH_VERSION}" ]; then
    # zshの補完関数のパスを追加
    fpath=($SCRIPT_DIR/comp $fpath)
elif [ -n "${BASH_VERSION}" ]; then
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
    source $SCRIPT_DIR/source/git_env.sh
fi

source $SCRIPT_DIR/../setup_utils/unset_utils.sh