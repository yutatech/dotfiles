SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $SCRIPT_DIR/../../setup_utils/utils.sh



mkdir -p $SCRIPT_DIR/../completion

TARGET_DIR=$SCRIPT_DIR/../completion/zsh-autosuggestions

if [ ! -d "$TARGET_DIR" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $TARGET_DIR
fi

COMMANDS="zsh"
check_and_install_commands "$COMMANDS"