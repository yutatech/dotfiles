# export command
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
PROXY_DIR=$(dirname "$SCRIPT_DIR")


export PATH="$PROXY_DIR/cmd:$PATH"
eval "$(register-python-argcomplete proxy)"

unset SCRIPT_DIR
unset PROXY_DIR

# configurations
export PROXY_PORT=1080
export PROXY_SERVER=""