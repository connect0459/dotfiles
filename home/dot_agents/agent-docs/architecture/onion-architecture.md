# オニオンアーキテクチャ実装ガイド

## 概要

GoやRustでのバックエンド開発では、オニオンアーキテクチャをベースに構成します。
レイヤー間の依存関係を厳格に管理し、ドメイン層を中心とした設計を行います。

## ディレクトリ構造

### Go プロジェクト

```text
internal/
├── application/      # アプリケーション層
│   ├── dtos/         # DTO (Data Transfer Objects)
│   ├── errors/       # アプリケーション固有のエラー
│   └── services/     # アプリケーションサービス
├── domain/           # ドメイン層（コア）
│   ├── entities/     # ドメインオブジェクト
│   ├── repositories/ # 抽象型でリポジトリを定義
│   └── services/     # ドメインサービス
├── infrastructure/   # インフラ層
│   ├── configs/      # アプリケーション設定
│   ├── database/     # DB接続
│   ├── env/          # 環境変数管理
│   └── persistence/  # リポジトリの実装
├── presentation/     # プレゼンテーション層
│   ├── handlers/     # ハンドラー
│   ├── middlewares/  # ミドルウェア
│   └── routes/       # ルーティング設定
└── registry/         # DIコンテナ
```

### Rust プロジェクト

```text
src/
├── application/      # アプリケーション層
├── domain/           # ドメイン層
├── infrastructure/   # インフラ層
├── presentation/     # プレゼンテーション層
└── registry/         # DIコンテナ
```

## レイヤー間の依存関係ルール

### 依存方向

```text
Presentation → Application → Domain ← Infrastructure
```

- **ドメイン層**: 他のレイヤーに依存しない（最も内側）
- **アプリケーション層**: ドメイン層のみに依存
- **インフラ層**: ドメイン層の抽象型を実装（依存性逆転）
- **プレゼンテーション層**: アプリケーション層に依存

### 重要原則

1. **依存性逆転の原則**: インフラ層はドメイン層で定義されたinterfaceを実装
2. **抽象型経由**: レイヤー間の通信は必ず抽象型（interface）を介す
3. **Rich Domain Objects**: ドメイン層にビジネスロジックを集約

## 境界とレイヤーの違い

依存方向を揃えること（依存性逆転・抽象型経由）はレイヤー間の呼び出し規約を整えるものであり、それ自体は変更の伝播を止める境界を作らない。

- インフラ層の実装をドメイン層の抽象型に依存させても、抽象型（interface）の形がインフラ側の都合（DBのテーブル粒度、外部APIのレスポンス形状）を反映していれば、依存の向きに関わらず意味的な結合は残る。
- 「レイヤーが分かれている」ことと「変更がそのレイヤーに閉じる」ことは別の主張であり、後者を保証するのは依存方向ではなく境界での型変換である。

### 境界＝型を変えること

信頼できない入力（HTTPリクエスト、外部APIレスポンスなど）をそのままの形でドメイン層まで通過させない。境界では「正しいか検査してそのまま通す（validate）」のではなく「正しければ別の型に変換する（decode / parse, don't validate）」を行う。

- `validate`: 値の型は変わらず、正しさは呼び出し側の記憶に依存する。内側の関数は再検査が必要かどうか判断できない。
- `decode`: 変換に成功した値だけが内側の型を名乗れる。以降の関数は型を信頼でき、同じ検査を繰り返さない。

値オブジェクトのコンストラクタ（`NewEmail`, `NewMoney` 等）が既にこの役割を担っている。境界を越える箇所（Handler → Service）で、コンストラクタを通さない生の文字列・数値をそのまま内側へ渡さないことが、この原則の実務上の適用点になる。

### エラーは境界の種類で分類する

入力形式が不正な場合と、入力は正しいが業務ルールに反する場合を、同じエラー型・同じレスポンスで扱わない。

| 失敗の種類 | 原因 | レスポンス例 |
| :--- | :--- | :--- |
| 入力形式不正 | JSON構文エラー、必須フィールド欠落、値オブジェクトのコンストラクタ失敗 | 400 Bad Request |
| 業務ルール違反 | 重複登録、在庫不足、権限不足など、入力は妥当だが状態と矛盾 | 422 Unprocessable Entity |
| インフラ障害 | DB接続断、外部API障害など | 500 Internal Server Error |

実装例は `agent-docs/examples/repository-pattern.md` の「境界でのエラー分類」を参照。

### 純粋性は責務の性質であってレイヤーの性質ではない

「ドメイン層はI/Oを行わない」というルールをレイヤーの制約として運用すると、ドメイン層の一操作が複数のリポジトリ呼び出しを内包しても「ドメイン層に置いたから正しい」と誤認しやすい。純粋性は個々の関数・メソッドの性質であり、レイヤーに配置しただけでは得られない。

- 判断（純粋な計算）とI/O（リポジトリ・外部API呼び出し）を分離し、判断側の関数はリポジトリを引数に取らない形で書く。
- 呼び出し側（アプリケーション層）が、純粋な判断とI/Oを組み合わせる。
- この分離により、判断のテストにI/Oのモックが不要になる。テスト容易性はレイヤーではなく、この分離から生まれる。

## リポジトリパターンの実装

詳細な実装例は `agent-docs/examples/repository-pattern.md` を参照してください。

### 基本方針

```go
// domain/repositories/user_repository.go（抽象型定義）
package repositories

type UserRepository interface {
    FindByID(id string) (*entities.User, error)
    Save(user *entities.User) error
}
```

```go
// infrastructure/persistence/user_repository.go（実装）
package persistence

import "myapp/internal/domain/repositories"

type gormUserRepository struct {
    db *gorm.DB
}

// 戻り値は抽象型（interface）
func NewGormUserRepository(db *gorm.DB) repositories.UserRepository {
    return &gormUserRepository{db: db}
}
```

## スケールを考慮した構成

規模が大きくなるとフラットなオニオンアーキテクチャはコードの凝集度が低下する可能性があります。
その場合、Package by Featuresパターンと組み合わせることを検討してください。

```text
internal/
├── features/
│   ├── users/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   └── orders/
│       ├── domain/
│       ├── application/
│       ├── infrastructure/
│       └── presentation/
└── shared/
    └── domain/
```

## フルスタックフレームワークの扱い

Laravelなどのフルスタックフレームワークを使用する場合は、オニオンアーキテクチャではなく、
**フレームワークの標準的な構成（MVC + Service層など）に従います**。

```text
app/ (Laravel の例)
├── Http/
│   ├── Controllers/  # コントローラー
│   ├── Middleware/   # ミドルウェア
│   └── Requests/     # フォームリクエスト
├── Models/           # Eloquent モデル
├── Services/         # ビジネスロジック層
└── Repositories/     # リポジトリ層（必要に応じて）
```

フレームワークの思想や慣習を尊重し、そのエコシステムの利点を最大限活用することを優先します。
