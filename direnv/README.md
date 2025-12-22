# direnv

## 概要
direnvは、ディレクトリごとに環境変数を自動的に読み込むツールです。
プロジェクトごとに異なる環境設定を簡単に管理できます。

## セットアップ
dotfile.bash または dotfile.zsh を読み込むと、direnv コマンドが利用可能になります。

初回実行時に自動的にセットアップが促されます：
```bash
direnv
# "direnv configuration is not completed. Would you like to configure it now? (y/n)"
# y を入力するとセットアップが開始されます
```

手動でセットアップする場合：
```bash
./direnv/scripts/setup_direnv.sh
```

## 使い方
1. プロジェクトディレクトリに `.envrc` ファイルを作成
2. 環境変数を設定（例：`export PROJECT_ENV=development`）
3. `direnv allow` でファイルを許可
4. ディレクトリに入ると自動的に環境変数が読み込まれます

## 対応環境
- macOS (Homebrew)
- Linux (apt)
- bash
- zsh
