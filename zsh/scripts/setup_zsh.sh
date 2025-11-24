#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/../../setup_utils/utils.sh

TARGET_DIR=$SCRIPT_DIR/../completion
mkdir -p $TARGET_DIR

repos=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting"
)

for repo in "${repos[@]}"; do
  dir="$TARGET_DIR/$(basename "$repo")"
  [ -d "$dir" ] || git clone --depth 1 "$repo" "$dir"
done

COMMANDS="zsh"
check_and_install_commands "$COMMANDS"

# $HOME/.zshrc が存在しない場合は、作成
if [ ! -f "$HOME/.zshrc" ]; then
  REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
  echo "Creating $HOME/.zshrc"
  touch "$HOME/.zshrc"
  echo "# Zsh configuration file" > "$HOME/.zshrc"
  echo "source $REPO_DIR/dotfile.zsh" >> "$HOME/.zshrc"
fi

# 現在のdefault shell を取得
if [[ "$OSTYPE" == "darwin"* ]]; then
  CURRENT_SHELL=$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')
else
  CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
fi

# zsh のパスを取得
ZSH_PATH=$(which zsh)

# default shell が zsh でない場合は変更
if [ ! "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
  # ユーザーに変更の確認
  echo "Current shell is not zsh. Would you like to change default shell now? (y/n)"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    chsh -s "$ZSH_PATH"
  fi
fi