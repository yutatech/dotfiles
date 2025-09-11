#!/bin/sh
set -e
# ros2 configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source $SCRIPT_DIR/../setup_utils/utils.sh

SOURCE_FILES=""

if [ -n "${ZSH_VERSION}" ]; then
    SOURCE_FILES="
        $SOURCE_FILES
        /opt/ros/humble/setup.zsh
    "
elif [ -n "${BASH_VERSION}" ]; then
    SOURCE_FILES="
        $SOURCE_FILES
        /opt/ros/humble/setup.bash
    "
fi

CHECK_FILES=""

SYMLINKS=""


COMMANDS=""

is_configure_completed "$SOURCE_FILES $CHECK_FILES" "$SYMLINKS" "$COMMANDS"
CONFIG_COMPETED=$?

if [ $CONFIG_COMPETED -eq 1 ]; then
    # 設定が完了していない場合は、コマンドを上書き
    source $SCRIPT_DIR/source/overwrite_command.sh
else
    source_all "$SOURCE_FILES"
    source $SCRIPT_DIR/source/ros2_env.sh
    ROS2_CONFIGURATION_COMPLETED=1
fi

source $SCRIPT_DIR/../setup_utils/unset_utils.sh