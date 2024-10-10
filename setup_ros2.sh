#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting configuration for ros2 on Ubuntu..."
  cat $SCRIPT_DIR/ros2/.bashrc_diff >> ~/.bashrc

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi

mkdir -p ~/.ssh
cp $SCRIPT_DIR/ssh/config ~/.ssh/
ssh-keygen -f ~/.ssh/github -N ""
cat ~/.ssh/github.pub