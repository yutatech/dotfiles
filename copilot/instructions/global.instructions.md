---
applyTo: "**"
---

## Implementtation steps
respond in japanese
1. Ask user before implementation
2. Use #tool:askQuestions tool
3. Build after implementing
4. Launch after build success
5. If there are errors, report to user and fix them

## Ask User before implementation
- 要求仕様に対して疑問や矛盾がある場合、もしくは方針が複数考えられる場合は、実装前に質問すること。
- ユーザーに質問するときは #tool:askQuestions を用いること
- ユーザーが質問している場合、それに対する回答を示した上でユーザーの返答を待ってから実装を始めること
- 既存の実装パターンを確認した上で仕様に疑問があれば質問すること
- 方針がいくつかある場合も選択肢を示してユーザーに確認すること

## Use #tool:askQuestions tool
- 疑問点を #tool:askQuestions を用いて質問してから実装を始めること
- ただしリポジトリ全体を確認してからユーザーに質問すること
- いかなる質問も #tool:askQuestions を用いて行うこと
- #tool:askQuestions を用いない質問を禁じる
- When calling #tool:askQuestions:
    - You MUST output valid JSON (RFC8259 compliant)
    - Do NOT include markdown links or URLs
    - Do NOT inline the JSON (must start on next line)
    - Escape quotes properly or avoid nested quotes
    - Use plain text inside options (no quotes inside strings)
```
#tool:askQuestions
[
  {
    "question": "質問文1",
    "options": ["option 1", "option2", "other"]
  },
  {
    "question": "質問文2",
    "options": ["options"]
  }
]
```

## Build after implementing
- build taskが定義されている場合、実装後にbuild taskを実行して、ビルドエラーがないか確認すること
- ビルドエラーがあれば修正すること

## Launch after build success
- launch taskが定義されている場合、build task 成功後に launch task を実行して、アプリケーションが正常に起動することを確認すること
- しばらく待ってからエラーメッセージらしきものが出力されないことを確認すること
- 待っている間も定期的に出力を確認して、エラーがあればすぐ対応すること
- 待ち時間は最大10秒程度でよい
- 出力が止まったら、アプリケーションが正常に起動したと判断してよい
- エラーメッセージらしきものが出力された場合は、エラー内容をユーザーに伝えてから修正すること

## Bugfix
- バグの原因に確証が持ててから修正すること
- 確証が持てない場合、ユーザーに検証の指示を依頼する、もしくはweb検索して原因を特定すること