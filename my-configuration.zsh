MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source $MY_CONFIGURATION_DIR/zsh/zsh.sh
source $MY_CONFIGURATION_DIR/git/git.sh
source $MY_CONFIGURATION_DIR/tmux/tmux.sh

source $MY_CONFIGURATION_DIR/setup_utils/unset_vars.sh

# 補完機能を有効にする
autoload -Uz compinit
compinit