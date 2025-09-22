#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)
source $REPO_DIR/setup_utils/utils.sh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # COMMANDS="google-chrome-stable"
    # echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrom-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    # curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/googlechrom-keyring.gpg
    # check_and_install_commands "$COMMANDS"

    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O $SCRIPT_DIR/chrome.deb
    sudo apt install $SCRIPT_DIR/chrome.deb
    rm $SCRIPT_DIR/chrome.deb
else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi