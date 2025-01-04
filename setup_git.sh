#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOSの場合
  echo "Setting up git on macOS..."

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Installing git on Ubuntu..."
  sudo apt install git -y

  cat $SCRIPT_DIR/git/.bashrc_diff >> ~/.bashrc

  curl -o ~/.git-completion.sh \  
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
  curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi

cp $SCRIPT_DIR/git/.gitconfig ~/
cp $SCRIPT_DIR/git/.gitignore_grobal ~/
