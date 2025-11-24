fcitx5() {
  echo "fcitx5 configuration is not completed. Would you like to configure it now? (y/n)"
  read answer
  if [ "$answer" = "y" ]; then
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    $SCRIPT_DIR/../scripts/setup_fcitx5.sh
    unset -f fcitx5 2>/dev/null
  fi
}