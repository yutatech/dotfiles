zsh() {
  echo "zsh configureation is not completed. Would you like to configure it now? (y/n)"
  read answer
  if [ "$answer" = "y" ]; then
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    $SCRIPT_DIR/../scripts/setup_zsh.sh
    unset -f zsh 2>/dev/null
    source $SCRIPT_DIR/../zsh.sh

    chsh -s $(which zsh)
  fi
}