#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)
source $REPO_DIR/setup_utils/utils.sh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  sudo apt reinstall refind -y
  sudo cp $REPO_DIR/refind/refind.conf /boot/efi/EFI/refind/refind.conf
  if sudo [ -e "/boot/efi/EFI/refind/themes/brads-refind-theme/theme.conf" ]; then
    echo "Pull refind theme"
    sudo git -C /boot/efi/EFI/refind/themes/brads-refind-theme pull
  else
    echo "Clone refind theme"
    sudo git clone https://github.com/toptensoftware/brads-refind-theme /boot/efi/EFI/refind/themes/brads-refind-theme
  fi

  echo "---"
  sudo efibootmgr
  echo "---"
  echo "please change efi boot order like \"sudo efibootmgr -o 0003,0000,0001,0002\""

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi