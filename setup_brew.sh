#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOSの場合
  echo "Installing Homebrew on macOS..."
  
  cd ~
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
  /bin/bash install.sh
  rm install.sh

else
  echo "Unsupported OS. This script supports macOS only."
  exit 1
fi
