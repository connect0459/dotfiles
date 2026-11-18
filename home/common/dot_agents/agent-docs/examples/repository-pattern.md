# リポジトリパターン実装例

## 基本方針

- **抽象型を先に定義**: ドメイン層でinterfaceを定義
- **実装はインフラ層**: 具体的な実装はinfrastructure層に配置
- **戻り値は抽象型**: コンストラクタは抽象型（interface）を返す
- **依存性逆転**: インフラ層がドメイン層に依存

## レイヤー間の依存関係

```text
domain/repositories/user_repository.go       (抽象型: UserRepository interface)
         ↑
         | 依存
         |
application/services/user_service.go         (抽象型: UserService interface + 実装)
         ↑
         | 依存
         |
presentation/handlers/user_handler.go        (抽象型: UserHandler interface + 実装)

infrastructure/persistence/user_repository.go (UserRepositoryの実装)
         |
         | 依存
         ↓
domain/repositories/user_repository.go       (抽象型: UserRepository interface)

registry/registry.go                         (各層の組み立て)
    → infrastructure層の具体的な実装を生成
    → application層のコンストラクタに注入
    → presentation層のコンストラクタに注入
```

## Go での実装例

### 1. ドメイン層: 抽象型定義

```go
// internal/domain/repositories/user_repository.go
package repositories

import (
    "errors"
    "myapp/internal/domain/entities"
)

// ErrUserNotFound はユーザーが見つからない場合に返す
// インフラ障害と区別するため、実装はこの値をラップして返す（生のドライバエラーをそのまま返さない）
var ErrUserNotFound = errors.New("user not found")

// UserRepository はユーザーの永続化を抽象化する
type UserRepository interface {
    FindByID(id string) (*entities.User, error)
    FindByEmail(email string) (*entities.User, error)
    Save(user *entities.User) error
    Delete(id string) error
}
```

### 2. インフラ層: GORM実装

```go
// internal/infrastructure/persistence/user_repository.go
package persistence

import (
    "errors"
    "myapp/internal/domain/entities"
    "myapp/internal/domain/repositories"
    "gorm.io/gorm"
)

// gormUserRepository はGORMを使用したUserRepositoryの実装
// 構造体は非公開（小文字始まり）
type gormUserRepository struct {
    db *gorm.DB
}

// NewGormUserRepository はGORM実装のUserRepositoryを生成する
// 戻り値は抽象型（repositories.UserRepository）
func NewGormUserRepository(db *gorm.DB) repositories.UserRepository {
    return &gormUserRepository{db: db}
}

func (r *gormUserRepository) FindByID(id string) (*entities.User, error) {
    var user entities.User
    if err := r.db.First(&user, "id = ?", id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, repositories.ErrUserNotFound
        }
        return nil, err // インフラ障害はそのまま伝播する
    }
    return &user, nil
}

func (r *gormUserRepository) FindByEmail(email string) (*entities.User, error) {
    var user entities.User
    if err := r.db.First(&user, "email = ?", email).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, repositories.ErrUserNotFound
        }
        return nil, err // インフラ障害はそのまま伝播する
    }
    return &user, nil
}

func (r *gormUserRepository) Save(user *entities.User) error {
    return r.db.Save(user).Error
}

func (r *gormUserRepository) Delete(id string) error {
    return r.db.Delete(&entities.User{}, "id = ?", id).Error
}
```

### 3. インフラ層: インメモリ実装（テスト用）

```go
// internal/infrastructure/memory/user_repository.go
package memory

import (
    "myapp/internal/domain/entities"
    "myapp/internal/domain/repositories"
    "sync"
)

// memoryUserRepository はインメモリのUserRepository実装
type memoryUserRepository struct {
    users map[string]*entities.User
    mu    sync.RWMutex
}

// NewUserRepository はインメモリ実装のUserRepositoryを生成する
func NewUserRepository() repositories.UserRepository {
    return &memoryUserRepository{
        users: make(map[string]*entities.User),
    }
}

func (r *memoryUserRepository) FindByID(id string) (*entities.User, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()

    user, exists := r.users[id]
    if !exists {
        return nil, repositories.ErrUserNotFound
    }
    return user, nil
}

func (r *memoryUserRepository) FindByEmail(email string) (*entities.User, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()

    for _, user := range r.users {
        if user.Email().String() == email {
            return user, nil
        }
    }
    return nil, repositories.ErrUserNotFound
}

func (r *memoryUserRepository) Save(user *entities.User) error {
    r.mu.Lock()
    defer r.mu.Unlock()

    r.users[user.ID()] = user
    return nil
}

func (r *memoryUserRepository) Delete(id string) error {
    r.mu.Lock()
    defer r.mu.Unlock()

    delete(r.users, id)
    return nil
}
```

### 4. アプリケーション層: 使用例

```go
// internal/application/services/user_service.go
package services

import (
    "errors"
    "myapp/internal/domain/entities"
    "myapp/internal/domain/repositories"
)

// ErrEmailAlreadyExists は業務ルール違反（重複登録）を表す
// 入力形式は妥当だが、現在の状態（既存ユーザーの存在）と矛盾する
var ErrEmailAlreadyExists = errors.New("email already exists")

// UserService はユーザー関連のユースケースを定義する
type UserService interface {
    CreateUser(email, password string) (*entities.User, error)
    FindUserByEmail(email string) (*entities.User, error)
}

// userService はUserServiceの実装（非公開）
type userService struct {
    userRepo repositories.UserRepository // 抽象型に依存
}

// NewUserService はUserServiceを生成する
func NewUserService(userRepo repositories.UserRepository) UserService {
    return &userService{
        userRepo: userRepo,
    }
}

func (s *userService) CreateUser(email, password string) (*entities.User, error) {
    // ここが境界: 生の文字列がドメインの値オブジェクトへdecodeされる
    // 失敗すれば *entities.ValidationError（入力形式不正）が返る
    emailVO, err := entities.NewEmail(email)
    if err != nil {
        return nil, err
    }

    passwordVO, err := entities.NewPassword(password)
    if err != nil {
        return nil, err
    }

    // この事前チェックはcheck-then-actであり、並行リクエストによる二重登録の窓を
    // 完全には塞げない。一意性の最終防衛線はDBのUNIQUE制約に置き、下のSaveが
    // その制約違反を返した場合もErrEmailAlreadyExistsとして扱う。
    _, err = s.userRepo.FindByEmail(emailVO.String())
    switch {
    case err == nil:
        return nil, ErrEmailAlreadyExists // 業務ルール違反: 既に存在する
    case errors.Is(err, repositories.ErrUserNotFound):
        // 未登録であり、想定どおりの経路。処理を継続する
    default:
        return nil, err // インフラ障害。未登録と誤認して処理を進めない
    }

    user := entities.NewUser(generateID(), emailVO, passwordVO)

    if err := s.userRepo.Save(&user); err != nil {
        // Save がDBのUNIQUE制約違反を検出した場合（実装はドライバ依存）も
        // ErrEmailAlreadyExists として扱い、事前チェックのレース窓を塞ぐ
        return nil, err // インフラ障害
    }

    return &user, nil
}

func (s *userService) FindUserByEmail(email string) (*entities.User, error) {
    return s.userRepo.FindByEmail(email)
}
```

### 4.5 境界でのエラー分類 — 入力形式不正・業務ルール違反・インフラ障害を区別する

`entities.NewEmail` / `NewPassword` の失敗（入力形式不正）と、`repositories.ErrUserNotFound`（未検出、正常系の一部）と、`ErrEmailAlreadyExists`（業務ルール違反）と、リポジトリのインフラ障害は、それぞれ原因が異なる。同じ `error` 型・同じ判定（`err == nil` など）に潰さず、`errors.Is` / `errors.As` で区別できる形にする。特に「未検出」と「インフラ障害」を区別しない実装は、DB障害を「未検出」と誤認して後続処理を継続させる欠陥を生みやすい。

```go
// internal/domain/entities/errors.go
package entities

import "fmt"

// ValidationError は値オブジェクトのコンストラクタ失敗を表す（入力形式不正）
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("%s: %s", e.Field, e.Message)
}
```

```go
// internal/domain/entities/email.go（NewEmailの変更点のみ）
func NewEmail(value string) (Email, error) {
    if value == "" {
        return Email{}, &ValidationError{Field: "email", Message: "cannot be empty"}
    }
    if !emailRegex.MatchString(value) {
        return Email{}, &ValidationError{Field: "email", Message: "invalid format"}
    }
    return Email{value: value}, nil
}
```

詳細な設計方針は `agent-docs/architecture/onion-architecture.md` の「境界とレイヤーの違い」を参照。

### 5. プレゼンテーション層: Handler

```go
// internal/presentation/handlers/user_handler.go
package handlers

import (
    "errors"
    "myapp/internal/application/services"
    "myapp/internal/domain/entities"
    "myapp/internal/domain/repositories"
    "net/http"

    "github.com/labstack/echo/v4"
)

// UserHandler はユーザー関連のHTTPハンドラを定義する
type UserHandler interface {
    CreateUser(c echo.Context) error
    FindUserByEmail(c echo.Context) error
}

// userHandler はUserHandlerの実装（非公開）
type userHandler struct {
    userService services.UserService // 抽象型に依存
}

// NewUserHandler はUserHandlerを生成する
func NewUserHandler(userService services.UserService) UserHandler {
    return &userHandler{
        userService: userService,
    }
}

func (h *userHandler) CreateUser(c echo.Context) error {
    var req struct {
        Email    string `json:"email"`
        Password string `json:"password"`
    }
    if err := c.Bind(&req); err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"}) // 入力形式不正
    }

    user, err := h.userService.CreateUser(req.Email, req.Password)

    var validationErr *entities.ValidationError
    switch {
    case errors.As(err, &validationErr):
        return c.JSON(http.StatusBadRequest, map[string]string{"error": validationErr.Error()}) // 400: 入力形式不正
    case errors.Is(err, services.ErrEmailAlreadyExists):
        return c.JSON(http.StatusUnprocessableEntity, map[string]string{"error": err.Error()}) // 422: 業務ルール違反
    case err != nil:
        return c.JSON(http.StatusInternalServerError, map[string]string{"error": "internal error"}) // 500: インフラ障害（詳細は返さない）
    }

    return c.JSON(http.StatusCreated, user)
}

func (h *userHandler) FindUserByEmail(c echo.Context) error {
    email := c.QueryParam("email")

    user, err := h.userService.FindUserByEmail(email)
    switch {
    case errors.Is(err, repositories.ErrUserNotFound):
        return c.JSON(http.StatusNotFound, map[string]string{"error": "user not found"}) // 404: 未検出
    case err != nil:
        return c.JSON(http.StatusInternalServerError, map[string]string{"error": "internal error"}) // 500: インフラ障害（詳細は返さない）
    }

    return c.JSON(http.StatusOK, user)
}
```

### 6. DIコンテナ: 依存性注入

```go
// internal/registry/registry.go
package registry

import (
    "myapp/internal/application/services"
    "myapp/internal/domain/repositories"
    "myapp/internal/infrastructure/persistence"
    "myapp/internal/presentation/handlers"
    "gorm.io/gorm"
)

// Registry はDIコンテナ
type Registry struct {
    db *gorm.DB
}

func NewRegistry(db *gorm.DB) *Registry {
    return &Registry{db: db}
}

func (r *Registry) newUserRepository() repositories.UserRepository {
    return persistence.NewGormUserRepository(r.db)
}

func (r *Registry) NewUserService() services.UserService {
    return services.NewUserService(r.newUserRepository())
}

func (r *Registry) NewUserHandler() handlers.UserHandler {
    return handlers.NewUserHandler(r.NewUserService())
}
```

### 7. ルーティング: エントリポイント

```go
// cmd/server/main.go
package main

import (
    "myapp/internal/registry"

    "github.com/labstack/echo/v4"
    "gorm.io/gorm"
)

func main() {
    db := setupDB() // *gorm.DB の初期化
    reg := registry.NewRegistry(db)

    e := echo.New()
    setupRoutes(e, reg)
    e.Logger.Fatal(e.Start(":8080"))
}

func setupRoutes(e *echo.Echo, reg *registry.Registry) {
    userHandler := reg.NewUserHandler()

    api := e.Group("/api")
    api.POST("/users", userHandler.CreateUser)
    api.GET("/users", userHandler.FindUserByEmail)
}
```

## アンチパターン

### ❌ 避けるべき実装

```go
// Bad: 具体的な型を返している
type GormUserRepository struct {
    db *gorm.DB
}

func NewGormUserRepository(db *gorm.DB) *GormUserRepository {
    return &GormUserRepository{db: db}
}
```

### ✅ 正しい実装

```go
// Good: 抽象型を返している
type gormUserRepository struct {
    db *gorm.DB
}

func NewGormUserRepository(db *gorm.DB) repositories.UserRepository {
    return &gormUserRepository{db: db}
}
```

## ポイント

1. **抽象型優先**: 各層でinterfaceを定義し、実装を隠蔽
2. **実装は非公開**: 実装の構造体は小文字始まり（非公開）
3. **戻り値は抽象型**: コンストラクタは必ず抽象型（interface）を返す
4. **テストはインメモリ**: モックではなく実際のインメモリ実装を使用
5. **依存性逆転**: 上位層のinterfaceに下位層が依存する
6. **組み立ては一箇所**: Registryが唯一具体的な実装を知る場所
7. **エラーは境界の種類で分類**: 入力形式不正(400)・業務ルール違反(422)・インフラ障害(500)を型で区別する。詳細は `agent-docs/architecture/onion-architecture.md` の「境界とレイヤーの違い」を参照
8. **「見つからない」と「インフラ障害」を混同しない**: リポジトリは両者を同じ`error`値で返さない。`err == nil`だけで分岐すると、DB障害を「未検出」と誤認して処理を継続する欠陥になる
9. **事前チェックは正当性の唯一の根拠にしない**: 一意性などの不変条件は、事前チェック（check-then-act）だけでなくDBの制約（UNIQUE等）を最終防衛線として持つ
