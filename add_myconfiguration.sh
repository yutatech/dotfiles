#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

if [ -n "${BASH_VERSION}" ]; then
    # bashの場合
  source $SCRIPT_DIR/setup_utils/add_line_to_bashrc.sh
  add_line_to_bashrc "source $SCRIPT_DIR/my-configuration.bash"
elif [ -n "${ZSH_VERSION}" ]; then
    # zshの場合
  source $SCRIPT_DIR/setup_utils/add_line_to_zshrc.sh
  add_line_to_zshrc "source $SCRIPT_DIR/my-configuration.zsh"
fi