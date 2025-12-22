#!/bin/sh
# direnv shell hook setup

if [ -n "${ZSH_VERSION}" ]; then
    # zsh hook
    eval "$(direnv hook zsh)"
elif [ -n "${BASH_VERSION}" ]; then
    # bash hook
    eval "$(direnv hook bash)"
fi
