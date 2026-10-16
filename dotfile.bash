export DOTFILES_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source $DOTFILES_REPO_DIR/zsh/zsh.sh
source $DOTFILES_REPO_DIR/bash/bash.sh
source $DOTFILES_REPO_DIR/git/git.sh
source $DOTFILES_REPO_DIR/git/git_comp.sh
source $DOTFILES_REPO_DIR/gh/gh.sh
source $DOTFILES_REPO_DIR/tmux/tmux.sh
source $DOTFILES_REPO_DIR/vscode/vscode.sh
source $DOTFILES_REPO_DIR/ros2/ros2.sh
source $DOTFILES_REPO_DIR/ros2/ros2_comp.sh
source $DOTFILES_REPO_DIR/fcitx5/fcitx5.sh
source $DOTFILES_REPO_DIR/vim/vim.sh
source $DOTFILES_REPO_DIR/refind/refind.sh
source $DOTFILES_REPO_DIR/chrome/chrome.sh
source $DOTFILES_REPO_DIR/ssh/ssh.sh
source $DOTFILES_REPO_DIR/terminal/terminal.sh
source $DOTFILES_REPO_DIR/docker/docker.sh
source $DOTFILES_REPO_DIR/direnv/direnv.sh

source $DOTFILES_REPO_DIR/setup_utils/unset_vars.sh

source $DOTFILES_REPO_DIR/dotfiles/update.sh