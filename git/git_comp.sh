if [ -n "${ZSH_VERSION}" ]; then
    _git_custom_commands() {
        local context state line
        declare -A opt_args

        _arguments -C \
            '(-): :->command'

        case $state in
            command)
            local -a custom_cmds
            custom_cmds=(
                'clear:delete all merged branches'
                'fixup:fix up a commit'
            )
            _describe -t command 'git command' custom_cmds
            ;;
        esac
        _git
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