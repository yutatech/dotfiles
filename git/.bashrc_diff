# git configuration

if [ -f ~/.git-completion.sh ]; then
    source ~/.git-completion.sh
fi
if [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
fi
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