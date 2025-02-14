MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source $MY_CONFIGURATION_DIR/bash/bash.sh
source $MY_CONFIGURATION_DIR/git/git.sh
source $MY_CONFIGURATION_DIR/tmux/tmux.sh
source $MY_CONFIGURATION_DIR/vscode/vscode.sh

# compinitを実行するので、他のcompinitより前に実行すべきものをzsh.shより前に実行する
source $MY_CONFIGURATION_DIR/zsh/zsh.sh

source $MY_CONFIGURATION_DIR/setup_utils/unset_vars.sh
