gh() {
  echo "gh configuration is not completed. Would you like to configure it now? (y/n)"
  read answer
  if [ "$answer" = "y" ]; then
    local SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    local REPO_DIR=$(cd $SCRIPT_DIR && git rev-parse --show-toplevel 2>/dev/null)
    $REPO_DIR/gh/scripts/setup_gh.sh
    unset -f gh 2>/dev/null
    source $REPO_DIR/gh/gh.sh
  fi
}