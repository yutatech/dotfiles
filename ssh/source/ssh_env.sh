# 自作サブコマンド
export PATH="$REPO_DIR/ssh/cmd:$PATH"

if [ -n "${ZSH_VERSION}" ]; then
    fpath=($REPO_DIR/ssh/comp $fpath)
elif [ -n "${BASH_VERSION}" ]; then
    _ssh_add_config() {
        COMPREPLY=()
    }
    complete -F _ssh_add_config ssh-add-config

    _ssh_github_register() {
        COMPREPLY=()
    }
    complete -F _ssh_github_register ssh-github-register

    _ssh_register() {
        COMPREPLY=()
    }
    complete -F _ssh_register ssh-register

    _ssh_setup() {
        COMPREPLY=()
    }
    complete -F _ssh_setup ssh-setup
fi