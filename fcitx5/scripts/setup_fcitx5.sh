#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting up fcitx5 on Ubuntu..."

  mkdir -p ~/.config/autostart/
  rm -rf ~/.config/fcitx5
  ln -sf $REPO_DIR/fcitx5/fcitx5 ~/.config/fcitx5
  ln -sf $REPO_DIR/fcitx5/fcitx5.desktop ~/.config/autostart/fcitx5.desktop

  sudo apt install fcitx5-mozc -y
  im-config -n fcitx5


  echo "fcitx5 setup is done. Please restart your computer."

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi