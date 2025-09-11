#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting up keyboard on Ubuntu..."

  # cp -r ./xkb ~/.xkb
  # echo "xkbcomp -I$HOME/.xkb ~/.xkb/keymap/kbd $DISPLAY> /dev/null" >> ~/.bashrc

  echo "Keyboard setup is done. Please restart your computer."

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi