#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)
source $REPO_DIR/setup_utils/utils.sh

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
    check_and_install_commands "wget gpg"

    KEY_FILE="/usr/share/keyrings/packages.microsoft.gpg"
    REPO_FILE="/etc/apt/sources.list.d/vscode.list"
    REPO_LINE="deb [arch=amd64 signed-by=${KEY_FILE}] https://packages.microsoft.com/repos/code stable main"

    # GPGキーの確認と追加
    if [ -f "$KEY_FILE" ]; then
      echo "✅ GPGキーは既に存在します: $KEY_FILE"
    else
      echo "🔑 GPGキーを追加します..."
      wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
      sudo install -o root -g root -m 644 packages.microsoft.gpg "$KEY_FILE"
      rm packages.microsoft.gpg
    fi

    # リポジトリの確認と追加
    if [ -f "$REPO_FILE" ] && grep -Fxq "$REPO_LINE" "$REPO_FILE"; then
      echo "✅ リポジトリは既に登録されています: $REPO_FILE"
    else
      echo "➕ リポジトリを追加します..."
      echo "$REPO_LINE" | sudo tee "$REPO_FILE" > /dev/null
      sudo apt update
    fi
    check_and_install_commands "code"
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