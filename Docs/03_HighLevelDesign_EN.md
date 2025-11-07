# High-Level Design

## 1. Architecture Overview
- **UI Layer:** SwiftUI views (`StockListView`, `ShoppingListView`, `ReceiptListView`, `SettingsView`, `RootView`).
- **Data Layer:** SwiftData models (`StockItem`, `ShoppingListEntry`, `Receipt`, `ReceiptItem`, `PendingSync`) stored in a shared `ModelContainer`.
- **Sync Layer:** `SyncService` orchestration plus per-entity repositories. `OfflineQueueService` manages retries.
- **Backend:** Supabase (PostgREST + Auth).  

Text diagram:  
User Actions → SwiftUI View → SwiftData `ModelContext` → (online) `SyncService` → Supabase  
↓ (offline) `PendingSync` queue → `OfflineQueueService` → retries when online.

## 2. Screen Map
| Screen | Purpose | Key Components |
| --- | --- | --- |
| Auth | Sign in / local-only toggle | `AuthView` |
| Stock | List items, edit, archive, add to shopping | `StockListView`, `StockListRow`, `StockItemSheet` |
| Shopping | Manage shopping entries, mark complete, save receipt | `ShoppingListView`, `ShoppingListRow` |
| Receipts | Show history, detail view | `ReceiptListView`, `ReceiptDetailView` |
| Settings | Sync status, manual actions, logout | `SettingsView` |

Navigation summary:  
`FamilyStockApp` → `RootView`. Authenticated users see a `TabView` with Stock / Shopping / Receipts / Settings. Non-authenticated users stay on `AuthView`. Sheets handle stock creation/editing and saving receipts.

## 3. Module Breakdown
| Module | Responsibilities | Example Files |
| --- | --- | --- |
| Stock | Inventory models, mapping, UI | `StockItem.swift`, `StockItem+Mapping.swift`, `StockItemSheet.swift`, `StockListView.swift`, `StockListRow.swift` |
| Shopping | Shopping entries + UI | `ShoppingListEntry.swift`, `ShoppingListEntry+Mapping.swift`, `ShoppingListView.swift` |
| Receipts | Receipt models and UI | `Receipt.swift`, `Receipt+Mapping.swift`, `ReceiptListView.swift`, `ReceiptDetailView.swift`, `ReceiptItem.swift` |
| Network | Sync + repositories + offline queue | `SyncService.swift`, `OfflineQueueService.swift`, `ItemRepository.swift`, `ShoppingListEntryRepository.swift`, `ReceiptRepository.swift`, `PendingSync.swift` |
| Auth / Helpers | Supabase auth, Secrets, utilities | `AuthView.swift`, `Secrets.plist`, helpers |
| Tests | Unit + UI coverage | `FamilyStockTests`, `FamilyStockUITests` |

## 4. Data Model Overview
- **StockItem:** Unique ID, user ID, quantities, category, timestamps, archive flag.
- **ShoppingListEntry:** Links to stock via `itemId`, desired quantity, completion/deletion flags.
- **Receipt + ReceiptItem:** Parent-child relationship with cascade delete; used to replenish inventory.
- **PendingSync:** Queue entries describing entity type, operation, retry metadata.

## 5. Sync Strategy
1. `pull*` methods fetch deltas from Supabase using `updated_at >= lastPull`.
2. DTOs are upserted into SwiftData (`StockItem.upsert`, etc.).
3. `push*` methods convert models to DTOs and call Supabase upsert/delete.
4. Failures enqueue a `PendingSync` item; `OfflineQueueService` later fetches and processes entries sequentially.
5. `RootView` and feature views trigger pulls/queue processing on lifecycle events (initial launch, scene activation).

## 6. Error Handling
- SwiftData save failures use `assertionFailure` with descriptive messages.
- Supabase failures log emoji-tagged console output and queue retries.
- Maximum retries per queue item = 5; dropped items require manual cleanup.

## 7. Test Plan Overview
| Layer | Coverage |
| --- | --- |
| Models | Constructors, SwiftData CRUD (`StockItemTests`). |
| Mapping | DTO ↔ model parity (`StockItemMappingTests`). |
| Services | Offline queue success/error paths (`OfflineQueueServiceTests`). |
| View Logic | Inventory/shopping behaviors (current coverage via `StockListViewSyncTests`, slated for refactor). |
| UI | Tab navigation, add/edit flows, shopping interactions (`FamilyStockUITests`). |

## 8. Configuration & Logging
- Supabase credentials live in `Secrets.plist` (with `.template` for onboarding).
- `AppStorage` keeps last pull timestamps per entity type.
- Logging uses emoji prefixes (e.g., `🔄`, `✅`, `❌`) for quick scanning of sync events.

## 9. Future Architecture Considerations
- DI for `SyncServiceProtocol` is partially in place, enabling more granular testing.
- `PendingSync` structure supports new entity types without schema changes.
- Accessibility identifiers (`AddItem`, `EditButton_<id>`, etc.) power UI automation and could back analytics.***
