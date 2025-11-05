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

    # Helper function to extract SSH hosts from config
    _scp_get_ssh_hosts() {
        local ssh_config="$HOME/.ssh/config"
        if [ -f "$ssh_config" ]; then
            grep '^Host ' "$ssh_config" 2>/dev/null | awk '{print $2}' | grep -v '[*?]' | sed 's/$/:/'
        fi
    }

    _scp() {
        local cur prev
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        
        # Find source and destination positions
        local source_idx=0
        local dest_idx=0
        local i
        for ((i=1; i<${#COMP_WORDS[@]}; i++)); do
            if [[ "${COMP_WORDS[i]}" != -* ]]; then
                if [ $source_idx -eq 0 ]; then
                    source_idx=$i
                else
                    dest_idx=$i
                    break
                fi
            fi
        done
        
        local is_destination=0
        if [ $COMP_CWORD -gt $source_idx ] && [ $source_idx -gt 0 ]; then
            is_destination=1
        fi
        
        # Case 1: host: pattern - complete with / and ~
        if [[ "$cur" =~ ^[^/~.]+:$ ]]; then
            COMPREPLY=( "/" "~" )
            return 0
        fi
        
        # Case 2: host:path pattern - complete remote files
        if [[ "$cur" =~ ^([^:]+):(.*)$ ]]; then
            local host="${BASH_REMATCH[1]}"
            local path="${BASH_REMATCH[2]}"
            local hostname="${host##*@}"
            local ssh_config="$HOME/.ssh/config"
            
            # Check if host exists in SSH config
            if [ -f "$ssh_config" ] && grep -q "^Host[[:space:]]\+$hostname[[:space:]]*$" "$ssh_config" 2>/dev/null; then
                # Get remote files without loading .rc files
                # Escape the path to prevent command injection
                local escaped_path=$(printf '%q' "$path")
                local remote_files=$(ssh -F "$ssh_config" -o 'BatchMode yes' -n "$hostname" "ls -dp ${escaped_path}* 2>/dev/null" 2>/dev/null)
                if [ -n "$remote_files" ]; then
                    COMPREPLY=( $(compgen -W "$remote_files" -P "${host}:" -- "$path") )
                fi
            fi
            return 0
        fi
        
        # Case 3: Starts with /, ~, or . - complete local files
        if [[ "$cur" =~ ^[/~.] ]]; then
            COMPREPLY=( $(compgen -f -- "$cur") )
            return 0
        fi
        
        # Case 4: Empty or other - depends on context
        if [ $is_destination -eq 1 ]; then
            # This is the destination argument
            local source="${COMP_WORDS[$source_idx]}"
            
            if [[ "$source" =~ ^[^:]+: ]]; then
                # Source is remote, destination should be local
                COMPREPLY=( $(compgen -f -- "$cur") )
            else
                # Source is local, destination can be remote or local
                local ssh_hosts=$(_scp_get_ssh_hosts)
                COMPREPLY=( $(compgen -f -- "$cur") )
                if [ -n "$ssh_hosts" ]; then
                    COMPREPLY+=( $(compgen -W "$ssh_hosts" -- "$cur") )
                fi
            fi
        else
            # This is the source argument
            local ssh_hosts=$(_scp_get_ssh_hosts)
            COMPREPLY=( $(compgen -f -- "$cur") )
            if [ -n "$ssh_hosts" ]; then
                COMPREPLY+=( $(compgen -W "$ssh_hosts" -- "$cur") )
            fi
        fi
    }
    complete -o nospace -F _scp scp
fi