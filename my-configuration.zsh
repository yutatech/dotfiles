MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source $MY_CONFIGURATION_DIR/setup_utils/add_line_to_zshrc.sh

DOTFILES_PARENT_DIR=$(cd $MY_CONFIGURATION_DIR/.. && pwd)

# bashrcからmy-configurationが含まれる行を削除
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/my-configuration/d' ~/.zshrc
else
    sed -i '/my-configuration/d' ~/.zshrc
fi

add_line_to_zshrc "source $DOTFILES_PARENT_DIR/dotfiles/dotfile.zsh"

mv $MY_CONFIGURATION_DIR $MY_CONFIGURATION_DIR/../dotfiles

source "$DOTFILES_PARENT_DIR/dotfiles/dotfile.zsh"