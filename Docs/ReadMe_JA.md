# FamilyStock

FamilyStock は、家庭内の消耗品を整理し、次回の買い物リストを自動で準備してくれるシンプルな iOS パントリーアプリです。SwiftUI / SwiftData / Supabase を用いたオフラインファースト構成で、ChatGPT Code と ClaudeCode による AI アシスト開発のデモとして実装されています。

## 特長

- **在庫管理** – アイテム/カテゴリごとの作成・編集・アーカイブ・残量管理。
- **買い物リスト自動化** – 在庫がゼロになったアイテムを自動でショッピングリストへ追加。
- **レシート履歴** – 完了済みの買い物エントリからレシートを作成し、支出を記録。
- **オフライン / クラウド同期** – 接続なしでもフル機能を提供し、オンライン時は Supabase と同期。

## アーキテクチャ概要

FamilyStock はオフラインファースト設計を採用し、SwiftData が常に信頼できるデータソースとなります。

- **SwiftUI**: タブ、シート、リスト行など UI 全般を担当。
- **SwiftData `@Model`**: `StockItem`, `ShoppingListEntry`, `Receipt`, `PendingSync` などローカル永続化。
- **`SyncService`**: `URLSession` + async/await で Supabase REST API との双方向同期を制御。
- **`OfflineQueueService`**: 失敗した push を `PendingSync` に積み、最大 5 回までリトライ。
- **ローカル専用モード**: Supabase を完全にバイパスする検証/プライバシー向けモードを提供。

## 必要環境

| ツール | バージョン |
| --- | --- |
| Xcode | 26.0.1 以降 (Xcode 16 beta) |
| macOS | 14.5 以降推奨 |
| iOS Deployment Target | iOS 26 (18.0) |
| Git | 最新 CLI |
| フレームワーク | SwiftUI, SwiftData, URLSession, SwiftTesting, XCTest/XCUITest |

> **補足:** 旧バージョンの iOS を対象にする場合は `IPHONEOS_DEPLOYMENT_TARGET` を手動で下げてください。現状は iOS 18 シミュレータを前提としています。

## セットアップ

### 1. リポジトリ取得

```bash
git clone https://github.com/Ailete619/family-stock FamilyStock
cd FamilyStock
```

### 2. 依存関係

SPM / CocoaPods の外部パッケージは不要です。ネットワークは `URLSession`、永続化は SwiftData を使用するため、Xcode 以外のセットアップは不要です。

### 3. `Secrets.plist` の作成

`FamilyStock/Secrets.plist`（テンプレートあり）を作成し、Supabase の URL と anon key を設定します。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://your-project.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>your-anon-public-key-here</string>
</dict>
</plist>
```

資格情報の取得手順:

1. [Supabase](https://supabase.com/) でプロジェクトを作成。
2. Project Settings → API で *Project URL* と *anon public key* をコピー。
3. `Secrets.plist` は `.gitignore` 済み。必ずバージョン管理から除外された状態を維持。

**ローカル専用モード:** `Secrets.plist` にダミー値を設定し、ログイン画面でローカル専用モードをオンにすれば Supabase を使用せず動作します。

### 4. アプリの実行

- **Xcode:** `FamilyStock.xcodeproj` を開き、iOS 18 以降のシミュレータ（例: iPhone 16 Pro）を選択して `⌘R`。
- **CLI:**

```bash
xcodebuild build \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

初回起動時はサインインまたはローカル専用モードの選択を求められます。ローカル専用モードではデータが端末内に留まり、Supabase サインイン時は複数デバイスで同期されます。

## テスト

### ユニットテスト

- **Xcode:** `⌘U` または Test Navigator を利用。
- **CLI:**

```bash
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockTests

# 特定スイート
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockTests/OfflineQueueServiceTests
```

カバレッジ概要:

- 30/30 テスト合格（モデル、同期サービス、オフラインキュー、仕様テストなど）。
- 制限事項は `FamilyStockTests/TESTING_NOTES.md` を参照（例: `StockListViewSyncTests` は想定仕様の検証用で、SwiftUI の実装自体は網羅していません）。

### UI テスト

- **Xcode:** Test Navigator の *FamilyStockUITests* から実行。
- **CLI:**

```bash
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockUITests

# 単一テストの例
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockUITests/FamilyStockUITests/testAddStockItem
```

UI テストはタブ遷移、在庫 CRUD、ショッピング管理、レシート作成をカバーしています。全テストはアクセシビリティ識別子を利用し、ローカル専用モードでの起動を前提とします（認証画面が表示されると失敗する場合があります）。

## 既知の問題と注意事項

- **デプロイターゲット:** 現状は Xcode 26 beta / iOS 18 シミュレータが必須。iOS 17 デバイスで実行するにはデプロイターゲットを下げる必要があります。
- **シミュレータ差異:** iPhone 16 Pro で検証済み。古いデバイスではレイアウトが異なる可能性があります。
- **Secrets.plist:** 未設定/不正な場合はアプリがクラッシュします。ローカル専用モードを利用するか、正しい Supabase キーを設定してください。
- **オフラインキュー:** 最大 5 回リトライ後にジョブを破棄します。破棄時はログに残り、手動対応が必要です。
- **UI テスト:** 認証 UI が先に出ると失敗する場合あり。事前にローカル専用モードへ切り替えてください。
- **ローカライズ:** 英語・フランス語・日本語に対応。UI テストはテキストではなく識別子に依存します。

## 開発メモ

### 設計方針

1. **オフラインファースト:** SwiftData を真のデータソースとし、ネットワーク同期はベストエフォート。
2. **ソフトデリート:** `isArchived` / `isDeleted` フラグで履歴を維持し、同期や監査を容易に。
3. **クライアント生成 ID:** オフラインでも重複しない UUID を生成し、サーバ衝突を回避。
4. **ラストライト勝ち:** `updatedAt` を用いた単純な競合解決（CRDT は採用せず）。
5. **外部依存なし:** すべて Xcode 標準ライブラリで完結。
6. **プロトコルベース同期:** `SyncServiceProtocol` でモックを差し替え、テスト性を確保。

### ディレクトリ構成

```
FamilyStock/
├── Stock/
├── Shopping/
├── Receipts/
└── Network/
```

各モジュールにモデル・ビュー・サービスが整理されています。

### オフラインキューフロー

```
ユーザー操作 → SwiftData 保存 → 同期試行
          ↓ 成功                     ↓ 失敗
      Supabase 更新         PendingSync に積む
                                ↓
                        アプリ起動 / 前面化で
                        自動的に再送
```

## ライセンス / 連絡先

本プロジェクトは **Loïc Henri LE TEXIER** によるポートフォリオ向けデモ（AI アシスト開発）です。ソースコードはリファレンス用途に限り閲覧可能で、再配布・商用利用は許可されていません。

質問やフィードバックは GitHub の issue、またはアカウント経由でご連絡ください。
