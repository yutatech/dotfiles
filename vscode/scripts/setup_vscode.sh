#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)

echo "$REPO_DIR"

if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command -v code &> /dev/null; then
    brew install --cask visual-studio-code
    sudo ln -s /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code /usr/local/bin/code
  fi    

  mkdir -p ~/Library/Application\ Support/Code/User
  ln -sf $REPO_DIR/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if ! command -v code &> /dev/null; then
    sudo snap install --classic code
  fi

  mkdir -p ~/.config/Code/User
  ln -sf $REPO_DIR/vscode/settings.json ~/.config/Code/User/settings.json

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi



# extensionのインストール

echo "Would you like to install vscode extensions now? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  echo "Installing extensions..."

  code --install-extension ms-vscode.cpptools-extension-pack
  code --install-extension cschlosser.doxdocgen
  code --install-extension mhutchie.git-graph
  code --install-extension github.copilot-chat
  code --install-extension eamodio.gitlens
  code --install-extension bierner.markdown-mermaid
  code --install-extension ms-python.python
  code --install-extension ms-vscode.makefile-tools
  code --install-extension ms-python.black-formatter
  code --install-extension oderwat.indent-rainbow
  code --install-extension ms-python.vscode-pylance
  code --install-extension visualstudioexptteam.vscodeintellicode
  code --install-extension kevinrose.vsc-python-indent
  code --install-extension njpwerner.autodocstring
fi