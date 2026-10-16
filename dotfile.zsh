# zmodload zsh/zprof

export DOTFILES_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source $DOTFILES_REPO_DIR/bash/bash.sh
source $DOTFILES_REPO_DIR/git/git.sh
source $DOTFILES_REPO_DIR/gh/gh.sh
source $DOTFILES_REPO_DIR/tmux/tmux.sh
source $DOTFILES_REPO_DIR/vscode/vscode.sh
source $DOTFILES_REPO_DIR/ros2/ros2.sh
source $DOTFILES_REPO_DIR/zsh/zsh.sh
source $DOTFILES_REPO_DIR/fcitx5/fcitx5.sh
source $DOTFILES_REPO_DIR/vim/vim.sh
source $DOTFILES_REPO_DIR/refind/refind.sh
source $DOTFILES_REPO_DIR/chrome/chrome.sh
source $DOTFILES_REPO_DIR/ssh/ssh.sh
source $DOTFILES_REPO_DIR/terminal/terminal.sh
source $DOTFILES_REPO_DIR/docker/docker.sh
source $DOTFILES_REPO_DIR/direnv/direnv.sh

source $DOTFILES_REPO_DIR/setup_utils/unset_vars.sh

######## compinit ##########
# 補完機能を有効にする
autoload -Uz compinit

ZCOMP_CACHEDUMP="$HOME/.zcompdump"
ZCOMP_HASHFILE="$DOTFILES_REPO_DIR/.zcompdump_fpath_hash"

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


source $DOTFILES_REPO_DIR/git/git_comp.sh
source $DOTFILES_REPO_DIR/ros2/ros2_comp.sh
source $DOTFILES_REPO_DIR/proxy/proxy.sh

# zprof

source $DOTFILES_REPO_DIR/dotfiles/update.sh