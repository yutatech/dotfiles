#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOSの場合
  echo "Setting up tmux on macOS..."
  brew install tmux

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntuの場合
  echo "Installing tmux on Ubuntu..."
  sudo apt install tmux -y

else
  echo "Unsupported OS. This script supports macOS and Ubuntu only."
  exit 1
fi

curl -o ~/.tmux-completion.bash \
  https://raw.githubusercontent.com/Bash-it/bash-it/refs/heads/master/completion/available/tmux.completion.bash


# TPM のインストール先ディレクトリ
TPM_DIR="$HOME/.tmux/plugins/tpm"

# TPM をインストール
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "TPM is already installed."
fi

# 設定ファイルのコピー
cp $SCRIPT_DIR/tmux/.tmux.conf ~/
cp $SCRIPT_DIR/tmux/.tmux.bash ~/

source $SCRIPT_DIR/add_line_to_bashrc.sh
add_line_to_bashrc "source ~/.tmux.bash"

# プラグインのインストール
tmux start-server
tmux new-session -d
"$TPM_DIR/bin/install_plugins"
tmux kill-server