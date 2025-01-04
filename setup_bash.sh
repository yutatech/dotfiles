#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting up bash on Ubuntu..."

  cp $SCRIPT_DIR/bash/.bash_config.bash ~/

  source $SCRIPT_DIR/add_line_to_bashrc.sh
  add_line_to_bashrc "source ~/.bash_config.bash"

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi