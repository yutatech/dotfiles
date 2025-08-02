if [ -n "$SSH_TTY" ] || [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
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
