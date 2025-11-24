vim() {
  echo "vim configureation is not completed. Would you like to configure it now? (y/n)"
  read answer
  if [ "$answer" = "y" ]; then
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    $SCRIPT_DIR/../scripts/setup_vim.sh
    unset -f vim 2>/dev/null
    source $SCRIPT_DIR/../vim.sh
  fi
}