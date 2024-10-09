#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Installing refind on Ubuntu..."
  sudo apt install refind -y
  sudo cp $SCRIPT_DIR/refind/refind.conf /boot/efi/EFI/refind/refind.conf
  sudo git clone https://github.com/toptensoftware/brads-refind-theme /boot/efi/EFI/refind/themes/brads-refind-theme

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi