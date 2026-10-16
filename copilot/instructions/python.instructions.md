---
description: "Use when writing or modifying Python code, logging, or command-line arguments."
applyTo: "**/*.py"
---

## Python

- ログ出力には標準ライブラリの `logging` を使用し、ログ目的で `print` を使用しない。通常のコマンド出力とは区別する。
- 各モジュールのロガーは `logging.getLogger(__name__)` で取得し、ログ設定はアプリケーションのエントリーポイントで行う。
- コマンドライン引数の解析には標準ライブラリの `argparse` を使用する。`sys.argv` を手動で解析しない。
- CLI アプリケーションでは `argparse` に `--log-level` 引数を定義し、`DEBUG`、`INFO`、`WARNING`、`ERROR`、`CRITICAL` からログレベルを選択できるようにする。既存の既定値がなければ `INFO` を使用する。
- 解析したログレベルを `logging` の設定に反映する。既存の引数解析やログ初期化がある場合はそこへ統合し、重複した設定を追加しない。
- ライブラリモジュールのインポート時に引数解析やルートロガーの設定を行わない。
