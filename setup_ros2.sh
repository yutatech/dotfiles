#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Setting configuration for ros2 on Ubuntu..."

else
  echo "Unsupported OS. This script supports Ubuntu only."
  exit 1
fi

# 設定ファイルのコピー
cp $SCRIPT_DIR/ros2/.ros2.bash ~/

source $SCRIPT_DIR/setup_utils/add_line_to_bashrc.sh
add_line_to_bashrc "source ~/.ros2.bash"