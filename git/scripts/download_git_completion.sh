# !/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

mkdir -p $SCRIPT_DIR/../completion

curl -o $SCRIPT_DIR/../completion/git-completion.bash \
  https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o $SCRIPT_DIR/../completion/git-prompt.sh \
  https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh