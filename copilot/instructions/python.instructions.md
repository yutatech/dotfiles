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


# Python Refactoring

- Keep `main()` as the top-level workflow: call each processing stage in order and pass each result explicitly to the next stage.
- Keep concrete implementation details out of `main()`; place each distinct responsibility in a focused function with clear inputs and outputs.
- Avoid deep helper call chains. Prefer orchestration at the entry point over a function that delegates through several layers of workflow functions.
- Extract repeated behavior into a shared helper when it removes real duplication; avoid wrappers that only rename or forward one call.
- Keep resource ownership, cleanup, and error handling at the narrowest lifecycle boundary that can guarantee cleanup.
- Remove functions, imports, constants, and branches that become unused after a refactor.
- Preserve existing behavior and public command-line interfaces unless the requested change requires otherwise.
- Validate all affected processing paths, including fallback or cached paths, after structural changes.

# xlwings
xlwingsのimportでCWDが変更されるため、必ずimport前のCWDを保存し、import後に復元すること。
```python
cwd = Path.cwd()
import xlwings as xw
os.chdir(cwd)
```