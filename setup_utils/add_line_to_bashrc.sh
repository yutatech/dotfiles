#!/usr/bin/env bash
set -e

# ファイルに特定の行が含まれていなければ追加する関数
add_line_to_bashrc() {
    local file_path="$HOME/.bashrc"
    local line_to_add="$1"

    # ファイルが存在しない場合は作成
    if [ ! -f "$file_path" ]; then
        echo "ERROR: $file_path does not exist."
    else
        if ! grep -Fxq "$line_to_add" "$file_path"; then
            echo "$line_to_add" >> "$file_path"
        fi
    fi
}
