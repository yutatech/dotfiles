# PowerShell

## 設定ファイルのシンボリックリンク

Git と VS Code のセットアップは、共通処理
[`Set-DotfilesSymbolicLink`](../setup_utils/pwsh.ps1) で設定ファイルをリンクします。
存在確認は内容ではなく、シンボリックリンクの種類と参照先で判定します。
正しいリンクが既にある場合、UAC は表示されません。

リンクの作成だけを別の PowerShell プロセスで管理者権限に昇格します。
親シェルやセットアップ全体は昇格しません。既存ファイル（ハードリンクを含む）は
同じディレクトリに `.dotfiles-backup-<ID>` 付きで退避します。
UAC をキャンセルした場合や作成に失敗した場合はエラーを報告し、
作成先が空なら既存ファイルを復元します。予期しない項目が作成先にある場合は
上書きせず、バックアップの場所を報告します。

## Unix 風プロセスコマンド

`bin` の `kill` と `pkill` は PowerShell 関数として読み込まれます。
`kill` は PID を指定し、`pkill` はプロセス名に対する正規表現で対象を選びます。

```powershell
kill 1234
kill -9 1234
kill -s TERM 1234
pkill '^python'
pkill -KILL '^python'
```

Windows は Linux のシグナルをサポートしないため、`TERM` は通常の `Stop-Process`、
`KILL` は `Stop-Process -Force` として処理します。対応シグナルは `TERM` と `KILL`
（`15` / `9`、`SIGTERM` / `SIGKILL` 表記を含む）のみです。
`pkill` の正規表現はプロセス名（拡張子を除く）に対して大文字小文字を区別し、
呼び出し元の PowerShell プロセスは対象から除外します。
Tab 補完では、`kill` に実行中プロセスの PID（プロセス名付き）、`pkill` に
プロセス名、`-s` / `--signal` の後に対応シグナルを候補表示します。

## Documents

[`create_document_symlink.ps1`](create_document_symlink.ps1) を手動実行すると、
`$HOME\Documents` から Windows の Documents フォルダーへのリンクを作成します。
Windows 側の Documents は事前に OneDrive など別の場所へ設定してください。
旧 `create_document_hardlink.ps1` はこの名前に変更しました。
リポジトリ内に旧スクリプトの呼び出し元はありません。

同じ参照先の既存ジャンクションはシンボリックリンクに置き換え、
成功後に旧ジャンクションだけを削除します。通常のディレクトリや
異なる参照先のディレクトリリンクは自動置換しません。

## 検証

`pwsh -NoProfile -File .\setup_utils\tests\pwsh.ps1`

一時ディレクトリと昇格処理のモックで検証します。
実際の UAC やユーザー設定の変更は行いません。
