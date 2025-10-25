# 自作サブコマンド
export PATH="$REPO_DIR/ssh/cmd:$PATH"

if [ -n "${ZSH_VERSION}" ]; then
    fpath=($REPO_DIR/ssh/comp $fpath)
elif [ -n "${BASH_VERSION}" ]; then
    _ssh_add_config() {
        local cur prev
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        
        case ${COMP_CWORD} in
            1)
                # ユーザー名の補完
                COMPREPLY=( $(compgen -u -- "$cur") )
                ;;
            2)
                # ホスト名の補完
                COMPREPLY=( $(compgen -A hostname -- "$cur") )
                ;;
            3)
                # 鍵ファイル名の補完（~/.sshディレクトリから）
                if [ -d ~/.ssh ]; then
                    COMPREPLY=( $(cd ~/.ssh && compgen -f -- "$cur") )
                fi
                ;;
        esac
    }
    complete -F _ssh_add_config ssh-add-config

    _ssh_github_register() {
        COMPREPLY=()
    }
    complete -F _ssh_github_register ssh-github-register

    _ssh_register() {
        local cur prev
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        
        case ${COMP_CWORD} in
            1)
                # ユーザー名の補完
                COMPREPLY=( $(compgen -u -- "$cur") )
                ;;
            2)
                # ホスト名の補完
                COMPREPLY=( $(compgen -A hostname -- "$cur") )
                ;;
        esac
    }
    complete -F _ssh_register ssh-register

    _ssh_setup() {
        COMPREPLY=()
    }
    complete -F _ssh_setup ssh-setup
fi