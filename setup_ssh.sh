#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOSの場合
  echo "Seeting up ssh on macOS..."

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Installing ssh on Ubuntu..."
  sudo apt install openssh-server -y

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi

mkdir -p ~/.ssh
cp $SCRIPT_DIR/ssh/config ~/.ssh/
ssh-keygen -f ~/.ssh/github -N ""
cat ~/.ssh/github.pub