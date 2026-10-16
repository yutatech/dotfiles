case $- in
    *i*) ;;
    *) return ;;
esac

DOTFILES_UPDATE_SCRIPT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)/scripts/dotfiles_update.sh"

case ":$PATH:" in
    *":$DOTFILES_REPO_DIR/dotfiles/cmd:"*) ;;
    *) export PATH="$DOTFILES_REPO_DIR/dotfiles/cmd:$PATH" ;;
esac

dotfiles-update() {
    local reload_script
    command bash "$DOTFILES_UPDATE_SCRIPT" update || return $?
    DOTFILES_UPDATE_STATE=current
    DOTFILES_UPDATE_HANDLED=1
    if [ -n "${ZSH_VERSION:-}" ]; then
        reload_script="$DOTFILES_REPO_DIR/dotfile.zsh"
    else
        reload_script="$DOTFILES_REPO_DIR/dotfile.bash"
    fi
    . "$reload_script" || return $?
    printf '%s\n' 'dotfiles: shell configuration reloaded.'
}

_dotfiles_update_prompt() {
    local previous_status=$? answer detail
    if [ -n "${DOTFILES_UPDATE_TEMP:-}" ] && [ -f "$DOTFILES_UPDATE_TEMP/state" ]; then
        IFS= read -r DOTFILES_UPDATE_STATE < "$DOTFILES_UPDATE_TEMP/state"
        DOTFILES_UPDATE_DETAIL=$(cat "$DOTFILES_UPDATE_TEMP/error")
        rm -rf -- "$DOTFILES_UPDATE_TEMP"
        DOTFILES_UPDATE_TEMP=
    fi
    case "${DOTFILES_UPDATE_STATE:-}" in
        available)
            if command git -C "$DOTFILES_REPO_DIR" merge-base --is-ancestor 'main@{upstream}' refs/heads/main 2>/dev/null; then
                DOTFILES_UPDATE_STATE=current
                return "$previous_status"
            fi
            printf '\033[33m[main update available]\033[0m\n'
            if [ "${DOTFILES_UPDATE_HANDLED:-0}" = 0 ]; then
                DOTFILES_UPDATE_HANDLED=1
                printf '%s' 'Update dotfiles main now? [y/N] '
                IFS= read -r answer || answer=
                case "$answer" in
                    y|Y) dotfiles-update ;;
                esac
            fi
            ;;
        error|diverged)
            if [ "${DOTFILES_UPDATE_HANDLED:-0}" = 0 ]; then
                DOTFILES_UPDATE_HANDLED=1
                if [ "$DOTFILES_UPDATE_STATE" = diverged ]; then
                    detail='main has diverged; automatic update is unavailable.'
                else
                    detail=${DOTFILES_UPDATE_DETAIL:-Background check failed; main or its upstream may not be configured.}
                fi
                detail=$(printf '%s' "$detail" | tr '\r\n' '  ' | cut -c 1-240)
                printf 'dotfiles: %s\n' "$detail"
            fi
            ;;
    esac
    return "$previous_status"
}

if [ "${DOTFILES_UPDATE_INITIALIZED:-0}" = 0 ]; then
    DOTFILES_UPDATE_INITIALIZED=1
    DOTFILES_UPDATE_STATE=checking
    DOTFILES_UPDATE_HANDLED=0
    DOTFILES_UPDATE_TEMP=$(mktemp -d)
    if [ -n "$DOTFILES_UPDATE_TEMP" ]; then
        (
            command bash "$DOTFILES_UPDATE_SCRIPT" check \
                >"$DOTFILES_UPDATE_TEMP/pending" 2>"$DOTFILES_UPDATE_TEMP/error"
            command mv -- "$DOTFILES_UPDATE_TEMP/pending" "$DOTFILES_UPDATE_TEMP/state"
        ) </dev/null >/dev/null 2>&1 &
        disown %+ 2>/dev/null || :
    else
        DOTFILES_UPDATE_STATE=error
        DOTFILES_UPDATE_DETAIL='Cannot create background check state.'
    fi
fi

if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _dotfiles_update_prompt
elif [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == 'declare -a '* ]]; then
    if [[ " ${PROMPT_COMMAND[*]} " != *' _dotfiles_update_prompt '* ]]; then
        PROMPT_COMMAND=('_dotfiles_update_prompt' "${PROMPT_COMMAND[@]}")
    fi
else
    case "${PROMPT_COMMAND:-}" in
        *'_dotfiles_update_prompt'*) ;;
        *) PROMPT_COMMAND="_dotfiles_update_prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
    esac
fi