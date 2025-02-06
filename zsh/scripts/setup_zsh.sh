SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/../../setup_utils/utils.sh



mkdir -p $SCRIPT_DIR/../completion

TARGET_DIR=$SCRIPT_DIR/../completion/

if [ ! -d "$TARGET_DIR/zsh-autosuggestions" ]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $TARGET_DIR/zsh-autosuggestions
fi

if [ ! -d "$TARGET_DIR/zsh-syntax-highlighting" ]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting $TARGET_DIR/zsh-syntax-highlighting
fi

COMMANDS="zsh"
check_and_install_commands "$COMMANDS"