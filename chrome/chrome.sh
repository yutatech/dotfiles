#!/bin/sh
# chrome configuration

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)
    source $REPO_DIR/setup_utils/utils.sh

    SOURCE_FILES=""

    CHECK_FILES=""

    SYMLINKS=""

    COMMANDS="google-chrome"

    is_configure_completed "$SOURCE_FILES $CHECK_FILES" "$SYMLINKS" "$COMMANDS"
    CONFIG_COMPETED=$?

    if [ $CONFIG_COMPETED -eq 1 ]; then
        # 設定が完了していない場合は、コマンドを上書き
        source $SCRIPT_DIR/source/overwrite_command.sh
    else
        alias chrome=google-chrome
    fi

fi
