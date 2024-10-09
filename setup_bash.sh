#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting up bash on Ubuntu..."
  cat $SCRIPT_DIR/bash/.bashrc_diff >> ~/.bashrc

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi