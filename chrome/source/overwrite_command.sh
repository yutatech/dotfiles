chrome() {
  echo "chrome configuration is not completed. Would you like to configure it now? (y/n)"
  read answer
  if [ "$answer" = "y" ]; then
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    local DOTFILES_REPO_DIR="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null)"
    $DOTFILES_REPO_DIR/chrome/scripts/setup_chrome.sh
    unset -f chrome 2>/dev/null
    source $DOTFILES_REPO_DIR/chrome/chrome.sh
  fi
}