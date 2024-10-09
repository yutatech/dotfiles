#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOSの場合
  echo "Installing VSCode on macOS..."
  
  # VSCodeをHomebrew経由でインストール
  if command -v brew &> /dev/null; then
    echo "Homebrew is installed. Installing VSCode..."
    brew install --cask visual-studio-code
  
    sudo ln -s /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code /usr/local/bin/code
  else
    echo "Homebrew is not installed. Please install Homebrew first."
    echo "Visit https://brew.sh for installation instructions."
    exit 1
  fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Installing VSCode on Ubuntu..."
  sudo snap install --classic code

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi

cp $SCRIPT_DIR/vscode/settings.json ~/.config/Code/User/settings.


# extensionのインストール
if [[ "$1" == "-e" ]]; then
  echo "The -e option was provided."
  echo "Installing extensions..."

  code --install-extension ms-vscode.cpptools-extension-pack
  code --install-extension cschlosser.doxdocgen
  code --install-extension mhutchie.git-graph
  code --install-extension github.copilot-chat
  code --install-extension eamodio.gitlens
  code --install-extension bierner.markdown-mermaid
  code --install-extension ms-python.python
  code --install-extension ms-vscode.makefile-tools

else
    echo "If you want to install extensions, please rerun the script with the -e option."
fi