# 自作サブコマンド
export PATH="$REPO_DIR/terminal/cmd:$PATH"

if [ -n "${ZSH_VERSION}" ]; then
    fpath=($REPO_DIR/terminal/comp $fpath)
elif [ -n "${BASH_VERSION}" ]; then
    _terminal_setup() {
        COMPREPLY=()
    }
    complete -F _terminal_setup terminal-setup
fi