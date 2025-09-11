#!/bin/sh
# refind configuration

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # 常にrefind コマンドでセットアップを実行
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
    source $SCRIPT_DIR/source/overwrite_command.sh
fi
