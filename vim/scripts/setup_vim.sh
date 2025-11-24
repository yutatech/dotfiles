#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)
source $REPO_DIR/setup_utils/utils.sh

COMMANDS=""

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOSの場合
  echo "Nothing to install on macOS for vim setup."

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  COMMANDS="vim vim-gtk"

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi

check_and_install_commands "$COMMANDS"

ln -sf $REPO_DIR/vim/.vimrc ~/