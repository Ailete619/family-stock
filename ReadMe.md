# FamilyStock

FamilyStock is a simple iOS pantry companion that keeps household consumables organized and automatically prepares your next shopping list. It’s an offline-first demo built with SwiftUI, SwiftData, and Supabase to showcase AI-assisted development (ChatGPT Code + ClaudeCode) in a modern Apple stack.

## Feature Highlights

- **Inventory management** – create, edit, archive, and track stock levels per item/category.
- **Shopping automation** – items that hit zero automatically appear in the shopping list.
- **Receipt history** – convert completed shopping entries into receipts to track spending.
- **Offline & cloud sync** – full functionality without connectivity, with Supabase sync when available.

## Architecture Snapshot

FamilyStock follows an offline-first design so the SwiftData store is always the source of truth:

- **SwiftUI** for all presentation layers (tabs, sheets, list rows).
- **SwiftData `@Model` classes** for local persistence (`StockItem`, `ShoppingListEntry`, `Receipt`, `PendingSync`).
- **`SyncService`** orchestrates pull/push with Supabase REST endpoints using `URLSession` + async/await.
- **`OfflineQueueService`** captures failed pushes in `PendingSync`, retrying up to 5 times on reconnect.
- **Local-only mode** skips Supabase entirely for privacy-friendly demos or testing.

## Requirements

| Tool | Version |
| --- | --- |
| Xcode | 26.0.1+ (Xcode 16 beta) |
| macOS | 14.5+ recommended |
| iOS Deployment Target | iOS 26 (18.0) |
| Git | Latest CLI |
| Frameworks | SwiftUI, SwiftData, URLSession, SwiftTesting, XCTest/XCUITest |

> **Note:** If you need to target older iOS versions, lower `IPHONEOS_DEPLOYMENT_TARGET` manually; this project currently assumes iOS 18 simulators.

## Setup

### 1. Clone

```bash
git clone https://github.com/Ailete619/family-stock FamilyStock
cd FamilyStock
```

### 2. Dependencies

No SPM/CocoaPods packages are required. Networking (Supabase REST) uses `URLSession`; persistence uses SwiftData. Nothing to install beyond Xcode.

### 3. Configure `Secrets.plist`

Create `FamilyStock/Secrets.plist` (a template is provided). Fill it with your Supabase URL + anon key:

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

How to get credentials:

1. Create a project on [Supabase](https://supabase.com/).
2. Project Settings → API → copy *Project URL* + *anon public* key.
3. Keep `Secrets.plist` out of source control (already gitignored).

**Local-only mode:** set any placeholder values in `Secrets.plist` and toggle local-only on the login screen to avoid Supabase entirely.

### 4. Run the App

- **Xcode:** open `FamilyStock.xcodeproj`, pick an iOS 18+ simulator (e.g., iPhone 16 Pro), press `⌘R`.
- **CLI:**

```bash
xcodebuild build \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

First launch prompts you to sign in or use local-only mode. Local-only keeps data on device; Supabase sync shares across devices.

## Testing

### Unit Tests

- **Xcode:** `⌘U` or use Test Navigator.
- **CLI:**

```bash
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockTests

# Specific suite
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockTests/OfflineQueueServiceTests
```

Coverage snapshot:

- 30/30 unit tests passing (models, sync services, offline queue, spec tests).
- See `FamilyStockTests/TESTING_NOTES.md` for limitations (e.g., `StockListViewSyncTests` exercise expected behavior, not actual SwiftUI flows).

### UI Tests

- **Xcode:** run suites under *FamilyStockUITests* in the Test Navigator.
- **CLI:**

```bash
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockUITests

# Single test example
xcodebuild test \
  -scheme FamilyStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FamilyStockUITests/FamilyStockUITests/testAddStockItem
```

UI coverage includes tab navigation, stock CRUD, shopping management, receipt creation. Tests rely on accessibility identifiers and expect the app to start in local-only mode—authentication prompts may need to be bypassed for automation.

## Known Issues & Caveats

- **Deployment target:** Xcode 26 beta / iOS 18 simulators are required today; lower the deployment target if you need iOS 17 hardware.
- **Simulator differences:** verified on iPhone 16 Pro; older devices may display minor layout changes.
- **Secrets & crashes:** the app will crash if `Secrets.plist` is missing/malformed. Use local-only mode or provide valid Supabase keys.
- **Offline queue:** retries up to five times before dropping a sync job. Dropped jobs remain logged for manual follow-up.
- **UI tests:** may fail if authentication UI appears first—toggle local-only mode before running.
- **Localization:** English, French, Japanese. UI tests use identifiers instead of localized strings.

## Development Notes

### Design Principles

1. **Offline-first:** SwiftData is the source of truth; network sync is best effort.
2. **Soft deletes:** `isArchived` / `isDeleted` flags keep history for sync + auditing.
3. **Client-generated IDs:** avoid server race conditions, simplify offline creation.
4. **Last-write-wins:** timestamps resolve conflicts without CRDT complexity.
5. **No third-party deps:** everything ships with Xcode.
6. **Protocol-based sync:** `SyncServiceProtocol` enables mocks for testing.

### File System Snapshot

```
FamilyStock/
├── Stock/
├── Shopping/
├── Receipts/
└── Network/
```

Each module contains its models + views/services as noted in the codebase.

### Offline Queue Flow

```
User action → SwiftData save → Sync attempt
        ↓ success                 ↓ failure
Supabase updated            PendingSync entry created
                               ↓
                       Automatic retries on
                       app launch / foreground
```

## License & Contact

This is a personal portfolio demo by **Loïc Henri LE TEXIER** (built with AI assistance). The code is copyrighted and provided for reference only—no redistribution or production use.

Questions or feedback? Open an issue or reach out via GitHub.
