MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source $MY_CONFIGURATION_DIR/bash/bash.sh
source $MY_CONFIGURATION_DIR/git/git.sh
source $MY_CONFIGURATION_DIR/tmux/tmux.sh
source $MY_CONFIGURATION_DIR/vscode/vscode.sh
source $MY_CONFIGURATION_DIR/ros2/ros2.sh
source $MY_CONFIGURATION_DIR/zsh/zsh.sh

source $MY_CONFIGURATION_DIR/setup_utils/unset_vars.sh

# 補完機能を有効にする
autoload -Uz compinit
compinit

source $MY_CONFIGURATION_DIR/git/git_comp.sh
source $MY_CONFIGURATION_DIR/ros2/ros2_comp.sh
