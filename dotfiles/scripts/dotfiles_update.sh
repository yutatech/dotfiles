#!/usr/bin/env bash

_dotfiles_git() {
    command git -C "$DOTFILES_REPO_DIR" "$@"
}

_dotfiles_kill_tree() {
    local parent="$1" child
    for child in $(ps -eo pid=,ppid= | awk -v parent="$parent" '$2 == parent { print $1 }'); do
        _dotfiles_kill_tree "$child"
    done
    kill -KILL "$parent" 2>/dev/null || :
}

_dotfiles_fetch() {
    local remote="$1" refspec="$2" result runner temporary ssh_command
    local fetch_arguments=(fetch --no-tags --no-write-fetch-head)
    temporary=$(mktemp -d) || return 1
    ssh_command="${GIT_SSH_COMMAND:-ssh} -oBatchMode=yes -oConnectTimeout=10"
    if [ "${DOTFILES_UPDATE_VERBOSE:-0}" = 1 ]; then
        fetch_arguments+=(--verbose)
    fi
    if IFS= read -r -t 10 result < <(
        if [ "${DOTFILES_UPDATE_VERBOSE:-0}" = 1 ]; then
            GIT_TERMINAL_PROMPT=0 SSH_ASKPASS_REQUIRE=never GIT_SSH_COMMAND="$ssh_command" \
                _dotfiles_git -c core.askPass= -c credential.interactive=false \
                "${fetch_arguments[@]}" -- "$remote" "$refspec" >&2
        else
            GIT_TERMINAL_PROMPT=0 SSH_ASKPASS_REQUIRE=never GIT_SSH_COMMAND="$ssh_command" \
                _dotfiles_git -c core.askPass= -c credential.interactive=false \
                "${fetch_arguments[@]}" -- "$remote" "$refspec" \
                >"$temporary/output" 2>"$temporary/error"
        fi
        printf '%s\n' "$?"
    ); then
        runner=$!
        wait "$runner" 2>/dev/null || :
        if [ "$result" != 0 ] && [ "${DOTFILES_UPDATE_VERBOSE:-0}" != 1 ]; then cat "$temporary/error" >&2; fi
    else
        runner=$!
        _dotfiles_kill_tree "$runner"
        wait "$runner" 2>/dev/null || :
        printf '%s\n' 'Git operation timed out after 10 seconds.' >&2
        result=124
    fi
    rm -rf -- "$temporary"
    return "$result"
}

_dotfiles_check() {
    local upstream remote merge contains_result forward_result
    DOTFILES_MAIN=$(_dotfiles_git rev-parse --verify refs/heads/main) || return 1
    upstream=$(_dotfiles_git rev-parse --symbolic-full-name 'main@{upstream}') || return 1
    remote=$(_dotfiles_git config --get branch.main.remote) || return 1
    merge=$(_dotfiles_git config --get branch.main.merge) || return 1
    if [ "$remote" != . ]; then
        _dotfiles_fetch "$remote" "+$merge:$upstream" || return 1
    fi
    DOTFILES_TARGET=$(_dotfiles_git rev-parse --verify 'main@{upstream}^{commit}') || return 1
    _dotfiles_git merge-base --is-ancestor "$DOTFILES_TARGET" "$DOTFILES_MAIN"
    contains_result=$?
    if [ "$contains_result" -eq 0 ]; then
        DOTFILES_STATE=current
        return 0
    fi
    _dotfiles_git merge-base --is-ancestor "$DOTFILES_MAIN" "$DOTFILES_TARGET"
    forward_result=$?
    if [ "$forward_result" -eq 0 ]; then
        DOTFILES_STATE=available
    elif [ "$forward_result" -eq 1 ] && [ "$contains_result" -eq 1 ]; then
        DOTFILES_STATE=diverged
    else
        return 1
    fi
}

_dotfiles_update() {
    local common branch worktrees changes
    DOTFILES_UPDATE_VERBOSE=1
    common=$(_dotfiles_git rev-parse --path-format=absolute --git-common-dir) || return 1
    DOTFILES_LOCK="$common/dotfiles-update.lock"
    if ! mkdir -- "$DOTFILES_LOCK" 2>/dev/null; then
        printf '%s\n' 'dotfiles: another update is running, or a stale update lock exists.' >&2
        return 1
    fi
    trap 'rmdir -- "$DOTFILES_LOCK"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM HUP
    _dotfiles_check || return 1
    if [ "$DOTFILES_STATE" = current ]; then
        printf '%s\n' 'dotfiles: main is up to date.'
        return 0
    fi
    if [ "$DOTFILES_STATE" != available ]; then
        printf '%s\n' 'dotfiles: main has diverged; update refused.' >&2
        return 1
    fi
    branch=$(_dotfiles_git symbolic-ref --quiet HEAD) || branch=
    worktrees=$(_dotfiles_git worktree list --porcelain) || return 1
    if [ "$branch" = refs/heads/main ]; then
        changes=$(_dotfiles_git status --porcelain --untracked-files=all --ignore-submodules=none) || return 1
        if [ -n "$changes" ]; then
            printf '%s\n' 'dotfiles: working tree is not clean; main was not updated.' >&2
            return 1
        fi
        _dotfiles_git merge --ff-only --no-edit "$DOTFILES_TARGET" || return 1
    else
        if printf '%s\n' "$worktrees" | grep -Fx 'branch refs/heads/main' >/dev/null; then
            printf '%s\n' 'dotfiles: main is checked out in another worktree.' >&2
            return 1
        fi
        printf 'dotfiles: updating main %s -> %s\n' "$DOTFILES_MAIN" "$DOTFILES_TARGET"
        _dotfiles_git update-ref refs/heads/main "$DOTFILES_TARGET" "$DOTFILES_MAIN" || return 1
    fi
    printf '%s\n' 'dotfiles: main updated.'
}

case "${1:-}" in
    check)
        if _dotfiles_check; then
            printf '%s\n' "$DOTFILES_STATE"
        else
            printf '%s\n' error
            exit 1
        fi
        ;;
    update) _dotfiles_update ;;
    *) printf '%s\n' 'Usage: dotfiles_update.sh check|update' >&2; exit 2 ;;
esac