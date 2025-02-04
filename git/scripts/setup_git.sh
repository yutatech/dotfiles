#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

# gitがインストールされているか確認
if ! command -v git > /dev/null 2>&1; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOSの場合
    echo "Setting up git on macOS..."
    brew install git

  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Ubuntuの場合
    echo "Installing git on Ubuntu..."
    sudo apt install git -y

  else
    echo "Unsupported OS. This script supports macOS and Ubuntu only."
    exit 0
  fi
fi

echo "download_git_completion"
$SCRIPT_DIR/download_git_completion.sh
echo "create_config_symlink"
$SCRIPT_DIR/create_config_symlink.sh