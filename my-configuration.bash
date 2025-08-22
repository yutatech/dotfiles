MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source $MY_CONFIGURATION_DIR/setup_utils/add_line_to_bashrc.sh

DOTFILES_PARENT_DIR=$(cd $MY_CONFIGURATION_DIR/.. && pwd)

# bashrcからmy-configurationが含まれる行を削除
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/my-configuration/d' ~/.bashrc
else
    sed -i '/my-configuration/d' ~/.bashrc
fi

add_line_to_bashrc "source $DOTFILES_PARENT_DIR/dotfiles/dotfile.bash"

mv $MY_CONFIGURATION_DIR $MY_CONFIGURATION_DIR/../dotfiles

source "$DOTFILES_PARENT_DIR/dotfiles/dotfile.bash"