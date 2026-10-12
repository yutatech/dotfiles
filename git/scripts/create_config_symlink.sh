#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

DOTFILES_REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)

ln -sf $DOTFILES_REPO_DIR/git/.gitconfig ~/.gitconfig
ln -sf $DOTFILES_REPO_DIR/git/.gitignore_global ~/.gitignore_global