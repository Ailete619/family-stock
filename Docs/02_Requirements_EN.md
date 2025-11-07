# Requirements Specification

## 1. System Summary
FamilyStock is an iOS SwiftUI app backed by SwiftData for local persistence and Supabase for cloud sync. It must operate offline-first, queueing mutations in `PendingSync` and replaying them when the device reconnects.

## 2. Use Cases
1. **Create inventory items** with name, category, target quantity.
2. **Adjust stock levels**; auto-add depleted items to the shopping list.
3. **Maintain shopping entries** (quantities, notes, completion state).
4. **Save receipts** from completed entries and replenish inventory accordingly.
5. **Sync with Supabase** manually/automatically across devices.
6. **Configure settings** such as local-only mode or sign-out.

## 3. Functional Requirements
### 3.1 Inventory
- CRUD for `StockItem` including archive (soft delete).
- Track `quantityInStock` and `quantityFullStock`.
- Trigger ShoppingListEntry creation when `quantityInStock == 0`.

### 3.2 Shopping List
- Auto/manual creation of entries with desired quantity, unit, notes.
- Toggle completion; completed entries eligible for receipts.
- `isDeleted` flag to retain history without removing records.

### 3.3 Receipts
- Create `Receipt` + `ReceiptItem` instances with timestamps/amounts.
- Replenish associated `StockItem` quantities when receipt is saved.

### 3.4 Sync & Offline
- `SyncService` handles pull/push for items, shopping entries, receipts.
- Supabase repositories expose `fetchUpdatedSince`, `upsert`, `delete`.
- `OfflineQueueService` retries failed jobs up to 5 times, stores errors.
- Track last pull timestamps via `AppStorage`.

### 3.5 Auth & Settings
- Use Supabase Auth; guard writes without a valid `userId`.
- Local-only mode short-circuits pull/push calls but keeps local CRUD operational.

### 3.6 Testing
- Unit tests cover models, mapping logic, offline queue, and view-level behaviors.
- UI tests validate primary navigation, item creation, shopping flows.

## 4. Non-Functional Requirements
| Category | Requirement |
| --- | --- |
| Platforms | iOS 17+ (Simulator parity). |
| Performance | Lists of 200 items must render within 1s; network calls async. |
| Offline resilience | All CRUD must succeed offline; queued sync flushes later. |
| Security | Supabase Auth, HTTPS, Secrets stored in plist template. |
| Observability | Console logs for pull/push success/failure, retry counts. |
| Quality | Regression covered via unit + UI tests in CI. |

## 5. Data Requirements
| Model | Key Attributes |
| --- | --- |
| `StockItem` | `id`, `userId`, `name`, `category?`, `updatedAt`, `isArchived`, `quantityInStock`, `quantityFullStock` |
| `ShoppingListEntry` | `id`, `userId`, `itemId`, `desiredQuantity`, `unit`, `note?`, `updatedAt`, `isDeleted`, `isCompleted` |
| `Receipt` | `id`, `userId`, `shopName`, `timestamp`, `amount?`, `[ReceiptItem]` |
| `ReceiptItem` | `id`, `itemName`, `quantity`, `receipt` |
| `PendingSync` | `id`, `entityType`, `entityId`, `operation`, `createdAt`, `retryCount`, `lastAttempt?`, `errorMessage?` |

## 6. External Interfaces
- **Supabase REST:** Invoked via repositories with `HTTPClient`. All calls include RLS-friendly filters (user ID, updated timestamp).
- **Secrets Management:** `Secrets.plist` + template provide base URL and anon key.
- **Authentication:** `SupabaseClient.shared` exposes `currentUser` for `userId`.

## 7. Quality Assurance
- Swift Testing framework for unit tests (`StockItemTests`, `StockItemMappingTests`, `OfflineQueueServiceTests`, etc.).
- XCTest UI automation (`FamilyStockUITests`) for end-to-end flows.
- Critical paths such as ID normalization, offline queueing, and DTO mapping have dedicated coverage.

## 8. Future Considerations
- Household sharing / multi-user collaboration leveraging existing `userId`.
- Push notifications for reminders.
- OCR / media attachments for receipts.
These are out-of-scope for the initial release but informed current data design.***
