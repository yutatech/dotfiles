#!/bin/sh

git() {
  echo "git configureation is not completed. Would you like to configure it now? (y/n)"
  read answer
  if [ "$answer" = "y" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    $SCRIPT_DIR/setup_git.sh
    unset -f git 2>/dev/null
    source $SCRIPT_DIR/../git.sh
  fi
}