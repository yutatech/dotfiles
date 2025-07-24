if [ -n "${ZSH_VERSION}" ]; then
    typeset -gA _git_third_party_commands  # グローバル連想配列として宣言（既存なら無視される）

    _git_third_party_commands[clear]=":delete all merged branches"
    _git_third_party_commands[fixup]=":fix up a commit"

    compdef _git git

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