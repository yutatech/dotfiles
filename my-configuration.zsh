MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

DOTFILES_PARENT_DIR=$(cd $MY_CONFIGURATION_DIR/.. && pwd)

# bashrcからmy-configurationが含まれる行を削除
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|source .*my-configuration\.zsh|source $DOTFILES_PARENT_DIR/dotfiles/dotfile.zsh|" ~/.zshrc
else
    sed -i "s|source .*my-configuration\.zsh|source $DOTFILES_PARENT_DIR/dotfiles/dotfile.zsh|" ~/.zshrc
fi

mv $MY_CONFIGURATION_DIR $MY_CONFIGURATION_DIR/../dotfiles

source "$DOTFILES_PARENT_DIR/dotfiles/dotfile.zsh"