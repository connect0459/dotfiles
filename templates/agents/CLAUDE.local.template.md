# CLAUDE.local.md - template

## Primary Directive

- Think in English, and follow the user's global `CLAUDE.md` for interactions with the user.

## Development Workflows

- `CLAUDE.md` 、 `docs/todo.md` を読み、実装を進めてください。
- `CLAUDE.md` の `## Development Philosophy` は遵守してください。
  - Red/Green TDDに従って実装を進めてください。
  - ドメインオブジェクトの設計は特に注意してください。
    - 構造体の本体やフィールドは基本privateにする。
      - 本体は基本privateだが、publicになることも許容する。
      - フィールドは直露出ではなく、ドメインオブジェクトの振る舞いとして実装する。
        - NG: `Person.name`
        - OK: `Person.name()`
    - 継承は使わず、移譲で共通ロジックの切り出しを模索すること。
- コミットは関心別に分けてください。
  - 実装と `docs/todo.md` のコミットは分けてください。
- 注意点:
  - ファイルのテキスト・コメント/コミットメッセージ等にローカル専用ファイルのパスや名前（ `.connect0459/...` など）を書かないでください。
  - 「xxxを参考にした」のようなコメントやdocstringは基本的に書かないでください。理由は、docstringなどはその実装の振る舞いを明示すべきで、実装経緯や理由はよっぽど非自明でない限りは不要と考えているためです。
