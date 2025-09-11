#!/bin/sh
set -e
# docker configuration
source $REPO_DIR/setup_utils/utils.sh

SOURCE_FILES=""

CHECK_FILES=""

SYMLINKS=""

COMMANDS="docker"

is_configure_completed "$SOURCE_FILES $CHECK_FILES" "$SYMLINKS" "$COMMANDS"
CONFIG_COMPETED=$?

if [ $CONFIG_COMPETED -eq 1 ]; then
    # 設定が完了していない場合は、コマンドを上書き
    source $REPO_DIR/docker/source/overwrite_command.sh
else
    source_all "$SOURCE_FILES"
fi

source $REPO_DIR/setup_utils/unset_utils.sh