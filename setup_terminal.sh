#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting up Terminal on Ubuntu..."

  # 設定ファイルの書き出し方法は以下
  # dconf dump /org/gnome/terminal/ > gnome-terminal-settings.dconf

  dconf load /org/gnome/terminal/ < $SCRIPT_DIR/terminal/gnome-terminal-settings.dconf

  echo "Terminal setup is done."

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi