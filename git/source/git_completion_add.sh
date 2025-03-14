if [ -n "${ZSH_VERSION}" ]; then
    _git_custom_commands() {
        _git

        local -a _descriptions _values
        _descriptions=('clear -- delete all merged branches')
        _values=('clear')
        compadd -d _descriptions -a _values
    }
    compdef _git_custom_commands git
elif [ -n "${BASH_VERSION}" ]; then
    _git_clear() {
        COMPREPLY=()
    }
    complete -F _git_clear git-clear
fi