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
