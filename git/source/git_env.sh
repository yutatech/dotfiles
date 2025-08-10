SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

# 自作サブコマンド
export PATH="$REPO_DIR/git/cmd:$PATH"

if [ -n "${ZSH_VERSION}" ]; then
  # vcs_info
  autoload -Uz vcs_info
  autoload -Uz add-zsh-hook
  
  zstyle ':vcs_info:*' formats '%F{green}(%s)-[%b]%f'
  zstyle ':vcs_info:*' actionformats '%F{red}(%s)-[%b|%a]%f'
  
  function _update_vcs_info_msg() {
      LANG=en_US.UTF-8 vcs_info
      RPROMPT="${vcs_info_msg_0_}"
  }
  add-zsh-hook precmd _update_vcs_info_msg

  # zshの補完関数のパスを追加
  fpath=($REPO_DIR/git/comp $fpath)
elif [ -n "${BASH_VERSION}" ]; then
  GIT_PS1_SHOWDIRTYSTATE=true
  GIT_PS1_SHOWUNTRACKEDFILES=true
  GIT_PS1_SHOWSTASHSTATE=true
  GIT_PS1_SHOWUPSTREAM=auto

  # PROMPT_COMMANDで右端に文字列を表示
  PROMPT_COMMAND='
  if [ -n "$(__git_ps1)" ]; then
    branch_name="$(__git_ps1)"
    # ターミナルの幅を取得
    columns=$(tput cols)
    # 右端に表示する文字列のフォーマット（緑色）
    branch_info="\033[1;32m$(__git_ps1)\033[00m"
    # 右端に配置するためのスペースを計算して配置
    printf -v right_prompt "%*s" $((columns - ${#branch_name})) ""
    echo -ne "${right_prompt}${branch_info}\r"
  fi
  '
fi
