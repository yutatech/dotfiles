MY_CONFIGURATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
REPO_DIR=$MY_CONFIGURATION_DIR

source $MY_CONFIGURATION_DIR/bash/bash.sh
source $MY_CONFIGURATION_DIR/git/git.sh
source $MY_CONFIGURATION_DIR/tmux/tmux.sh
source $MY_CONFIGURATION_DIR/vscode/vscode.sh
source $MY_CONFIGURATION_DIR/ros2/ros2.sh
source $MY_CONFIGURATION_DIR/zsh/zsh.sh
source $MY_CONFIGURATION_DIR/fcitx5/fcitx5.sh
source $MY_CONFIGURATION_DIR/vim/vim.sh
source $MY_CONFIGURATION_DIR/refind/refind.sh
source $MY_CONFIGURATION_DIR/chrome/chrome.sh
source $MY_CONFIGURATION_DIR/ssh/ssh.sh
source $MY_CONFIGURATION_DIR/terminal/terminal.sh
source $MY_CONFIGURATION_DIR/docker/docker.sh

source $MY_CONFIGURATION_DIR/setup_utils/unset_vars.sh

######## compinit ##########
# 補完機能を有効にする
autoload -Uz compinit

ZCOMP_CACHEDUMP="$HOME/.zcompdump"
ZCOMP_HASHFILE="$MY_CONFIGURATION_DIR/.zcompdump_fpath_hash"

autoload -Uz compinit

# fpath 全体の補完ファイルをハッシュ化
current_hash=$(
  LC_ALL=C find $fpath -type f -name '_*' -printf '%p %T@\n' 2>/dev/null \
  | LC_ALL=C sort \
  | sha1sum | awk '{print $1}'
)

saved_hash=$(cat "$ZCOMP_HASHFILE" 2>/dev/null)

if [[ "$current_hash" != "$saved_hash" ]]; then
  # fpath 内で変更があった → フル初期化
  echo "full compinit"
  compinit
  echo "$current_hash" > "$ZCOMP_HASHFILE"
else
  # 変更なし → キャッシュ利用
  compinit -C
fi
######## compinit ##########


source $MY_CONFIGURATION_DIR/git/git_comp.sh
source $MY_CONFIGURATION_DIR/ros2/ros2_comp.sh

unset REPO_DIR