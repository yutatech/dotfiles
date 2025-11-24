# export command
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

export PATH="$SCRIPT_DIR/cmd:$PATH"
if command -v register-python-argcomplete >/dev/null 2>&1; then
    eval "$(register-python-argcomplete proxy)"
fi

unset SCRIPT_DIR
unset PROXY_DIR

# configurations
# export PROXY_PORT=1080
# export PROXY_SERVER=""