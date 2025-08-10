MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
REPO_DIR=$MY_CONFIGURATION_DIR

source $MY_CONFIGURATION_DIR/zsh/zsh.sh
source $MY_CONFIGURATION_DIR/bash/bash.sh
source $MY_CONFIGURATION_DIR/git/git.sh
source $MY_CONFIGURATION_DIR/git/git_comp.sh
source $MY_CONFIGURATION_DIR/tmux/tmux.sh
source $MY_CONFIGURATION_DIR/vscode/vscode.sh
source $MY_CONFIGURATION_DIR/ros2/ros2.sh
source $MY_CONFIGURATION_DIR/ros2/ros2_comp.sh
source $MY_CONFIGURATION_DIR/fcitx5/fcitx5.sh
source $MY_CONFIGURATION_DIR/vim/vim.sh
source $MY_CONFIGURATION_DIR/refind/refind.sh
source $MY_CONFIGURATION_DIR/chrome/chrome.sh
source $MY_CONFIGURATION_DIR/ssh/ssh.sh
source $MY_CONFIGURATION_DIR/terminal/terminal.sh

source $MY_CONFIGURATION_DIR/setup_utils/unset_vars.sh

unset REPO_DIR