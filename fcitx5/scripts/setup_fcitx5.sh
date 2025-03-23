#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting up keyboard on Ubuntu..."

  sudo apt install fcitx5-mozc -y
  im-config -n fcitx5

  mkdir -p ~/.config/fcitx5/
  ln -sf $REPO_DIR/fcitx5/config ~/.config/fcitx5/config
  ln -sf $REPO_DIR/fcitx5/fcitx5.desktop ~/.config/autostart/fcitx5.desktop

  echo "Keyboard setup is done. Please restart your computer."

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi