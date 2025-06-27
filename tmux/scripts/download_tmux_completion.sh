# !/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

mkdir -p $SCRIPT_DIR/../completion

wget -O $SCRIPT_DIR/../completion/tmux.completion.bash \
  https://raw.githubusercontent.com/Bash-it/bash-it/refs/heads/master/completion/available/tmux.completion.bash