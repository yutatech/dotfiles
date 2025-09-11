#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

parent_shell=$(ps -o comm= -p "$PPID" | awk -F'/' '{print $NF}')

if [ $parent_shell = bash ]; then
  # bashの場合
  if [ ! -e "$HOME/.bashrc" ]; then
    touch ~/.bashrc
  fi
  source $SCRIPT_DIR/setup_utils/add_line_to_bashrc.sh
  add_line_to_bashrc "source $SCRIPT_DIR/dotfile.bash"
elif [ $parent_shell = zsh ]; then
  # zshの場合
  if [ ! -e "$HOME/.zshrc" ]; then
    touch ~/.zshrc
  fi
  source $SCRIPT_DIR/setup_utils/add_line_to_zshrc.sh
  add_line_to_zshrc "source $SCRIPT_DIR/dotfile.zsh"
fi