SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/add_line_to_zshrc.sh

git clone https://github.com/zsh-users/zsh-autosuggestion ~/.zsh/zsh-autosuggestions

add_line_to_zshrc "source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"