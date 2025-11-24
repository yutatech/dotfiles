if [ -n "${ZSH_VERSION}" ]; then
    :
elif [ -n "${BASH_VERSION}" ]; then
    _git_clear() {
        COMPREPLY=()
    }
    complete -F _git_clear git-clear
    _git_fixup() {
        COMPREPLY=()
    }
    complete -F _git_fixup git-fixup
fi