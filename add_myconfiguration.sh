#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

parent_shell=$(ps -o comm= -p "$PPID")

if [ $parent_shell = bash ]; then
    # bashの場合
  source $SCRIPT_DIR/setup_utils/add_line_to_bashrc.sh
  add_line_to_bashrc "source $SCRIPT_DIR/my-configuration.bash"
elif [ $parent_shell = zsh ]; then
    # zshの場合
  source $SCRIPT_DIR/setup_utils/add_line_to_zshrc.sh
  add_line_to_zshrc "source $SCRIPT_DIR/my-configuration.zsh"
fi