MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

DOTFILES_PARENT_DIR=$(cd $MY_CONFIGURATION_DIR/.. && pwd)

# bashrcからmy-configurationが含まれる行を削除
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|source .*my-configuration\.bash|source $DOTFILES_PARENT_DIR/dotfiles/dotfile.bash|" ~/.bashrc
else
    sed -i "s|source .*my-configuration\.bash|source $DOTFILES_PARENT_DIR/dotfiles/dotfile.bash|" ~/.bashrc
fi

mv $MY_CONFIGURATION_DIR $MY_CONFIGURATION_DIR/../dotfiles

source "$DOTFILES_PARENT_DIR/dotfiles/dotfile.bash"