#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOSの場合
  echo "Setting up vim on macOS..."

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Installing vim on Ubuntu..."
  sudo apt install vim vim-gtk -y

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi

cp $SCRIPT_DIR/vim/.vimrc ~/