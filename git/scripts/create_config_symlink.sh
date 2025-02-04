# !/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)

ln -s $REPO_DIR/git/.gitconfig ~/.gitconfig
ln -s $REPO_DIR/git/.gitignore_global ~/.gitignore_global