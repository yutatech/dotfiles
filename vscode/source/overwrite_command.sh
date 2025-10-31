# Check if running in SSH, VS Code terminal, or WSL environment
is_wsl() {
  [ -n "$WSL_DISTRO_NAME" ] || grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null
}

if [ -n "$SSH_TTY" ] || [ -n "$VSCODE_IPC_HOOK_CLI" ] || is_wsl; then
  :
else

code() {
  echo "code configureation is not completed. Would you like to configure it now? (y/n)"
  read answer
  if [ "$answer" = "y" ]; then
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    $SCRIPT_DIR/../scripts/setup_vscode.sh
    unset -f code 2>/dev/null
    source $SCRIPT_DIR/../vscode.sh
  fi
}

fi
