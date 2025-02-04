# TPM のインストール先ディレクトリ
TPM_DIR="$HOME/.tmux/plugins/tpm"

# TPM がセットアップ済みか確認する関数
is_tpm_setup() {
    [ -d "$TPM_DIR" ] && [ -x "$TPM_DIR/bin/install_plugins" ]
}

# 必要に応じて TPM をセットアップする関数
setup_tpm_if_needed() {
    if is_tpm_setup; then
        echo "TPM is already installed."
        return
    fi

    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"

    echo "Installing tmux plugins..."
    tmux start-server
    tmux new-session -d
    "$TPM_DIR/bin/install_plugins"
    tmux kill-server
}