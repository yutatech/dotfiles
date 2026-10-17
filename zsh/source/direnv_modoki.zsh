# ---- simple direnv-like .envrc loader for zsh ----

typeset -g _MY_ENVRC_CURRENT=""
typeset -g _MY_ENVRC_LOADING=0

_find_envrc() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.envrc" ]]; then
            print -r -- "$dir/.envrc"
            return 0
        fi
        dir="${dir:h}"
    done

    return 1
}

_load_envrc() {
    local envrc

    # 再入防止
    # .envrc 内で cd したり、source 中に何かが chpwd を呼ぶと無限ループする可能性があるため
    if (( _MY_ENVRC_LOADING )); then
        return
    fi

    _MY_ENVRC_LOADING=1

    envrc="$(_find_envrc)"

    # 見つからない場合
    if [[ -z "$envrc" ]]; then
        _MY_ENVRC_CURRENT=""
        _MY_ENVRC_LOADING=0
        return
    fi

    # 同じ .envrc なら何もしない
    if [[ "$envrc" == "$_MY_ENVRC_CURRENT" ]]; then
        _MY_ENVRC_LOADING=0
        return
    fi

    _MY_ENVRC_CURRENT="$envrc"

    print -u2 "[envrc] loading: $envrc"

    source "$envrc"

    _MY_ENVRC_LOADING=0
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _load_envrc

# シェル起動時にも一度実行
_load_envrc