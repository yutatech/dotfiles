#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting up keyboard for ThinkPad on Ubuntu..."

  sudo cp $SCRIPT_DIR/udev/hwdb.d/90-thinkpad.hwdb /etc/udev/hwdb.d/

  echo "Keyboard setup for ThinkPad is done. Please restart your computer."

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi