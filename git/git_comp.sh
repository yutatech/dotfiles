if [ -n "${ZSH_VERSION}" ]; then
    _git_custom_commands() {
        _git

        local -a _descriptions _values
        _descriptions=('clear -- delete all merged branches',
                       'fixup -- fix up a commit')
        _values=('clear' 'fixup')
        compadd -d _descriptions -a _values
    }
    compdef _git_custom_commands git

    _git-fixup() {
        __git_recent_commits
    }
    compdef _git-fixup git-fixup
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