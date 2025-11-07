# Detailed Design

## 1. Data Models

### 1.1 `StockItem`
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` (unique) | Lowercased UUID aligned with Supabase IDs. |
| `userId` | `String` | Owner (Supabase auth ID). |
| `name` | `String` | Item label. |
| `category` | `String?` | Optional grouping. |
| `updatedAt` | `Date` | Used for delta sync & conflict resolution. |
| `isArchived` | `Bool` | Soft delete flag. |
| `quantityInStock` | `Double` | Current stock. |
| `quantityFullStock` | `Double` | Target stock level. |

### 1.2 `ShoppingListEntry`
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Lowercased UUID. |
| `userId` | `String` | Owner. |
| `itemId` | `String` | FK to `StockItem`. |
| `desiredQuantity` | `Double` | Needed amount. |
| `unit` | `String` | Display unit. |
| `note` | `String?` | Optional instructions. |
| `updatedAt` | `Date` | Sync tombstone. |
| `isDeleted` | `Bool` | Marks entry removed post-receipt. |
| `isCompleted` | `Bool` | Checkbox status. |

### 1.3 `Receipt` / `ReceiptItem`
- `Receipt`: `id`, `userId`, `shopName`, `timestamp`, `amount?`, `@Relationship var items: [ReceiptItem]`.
- `ReceiptItem`: `id`, `itemName`, `quantity`, `receipt`.

### 1.4 `PendingSync`
| Field | Notes |
| --- | --- |
| `entityType` | `"StockItem"`, `"ShoppingListEntry"`, `"Receipt"` |
| `entityId` | Target ID |
| `operation` | `"upsert"`, `"delete"`, etc. |
| `createdAt` | Queue insertion time |
| `retryCount` | Incremented before each attempt (cap at 5) |
| `lastAttempt` | Timestamp of last try |
| `errorMessage` | Stored error text for diagnostics |

## 2. Service Behavior

### 2.1 `SyncService`
- **Pull path:**  
  - `pullItems`/`pullShopping`/`pullReceipts` compute `lastPull*` date.  
  - Repositories fetch updates via `updated_at >= lastPull`.  
  - DTOs are upserted into SwiftData; timestamps persisted.
- **Push path:**  
  - Convert models to DTO via `toDTO()`.  
  - Call repository `upsert`.  
  - On failure, invoke `offlineQueue.queueSync(entityType:item.id:operation:"upsert")`.
- **Delete operations:** Similar flow but use repository `delete`.
- **Lifecycle hooks:** Exposed helpers `processPendingSyncs` and `getPendingSyncCount`.

### 2.2 `OfflineQueueService`
1. `queueSync`: Insert `PendingSync` + immediate save. Spawn `Task` to `processPendingSyncs`.
2. `processPendingSyncs`:  
   - Guard `isProcessing`.  
   - Fetch pending items ordered by `createdAt`.  
   - Loop through `processSingleSync`.
3. `processSingleSync`:  
   - Drop entries with `retryCount >= 5`.  
   - Increment `retryCount`, set `lastAttempt`.  
   - Switch on `(entityType, operation)` to call `SyncService` methods.  
   - Success → delete queue entry; failure → persist `errorMessage`.

### 2.3 Repositories
- `ItemRepository`, `ShoppingListEntryRepository`, `ReceiptRepository` wrap HTTP verbs.  
- `fetchUpdatedSince` uses query params for user ID and timestamps.  
- `upsert` ensures the DTO contains the current user for RLS compliance.  
- Conflict detection uses `ConflictResolver` (last-write-wins).  
- `delete` executes Supabase `DELETE` with `id` filter; receipts also cascade delete their items.

## 3. UI Logic Details

### 3.1 `RootView`
- Observes `SupabaseClient.shared` for auth.  
- Initializes `SyncService` in `.task`.  
- On login or app foreground, kicks off `pullAll` / `processPendingSyncs`.

### 3.2 `StockListView` & `StockListRow`
- Filters out `isArchived` items before rendering.  
- `updateQuantity(_:)`: saves context, then (if online) spawns `Task` to `pushItem`.  
- `delete(_:)`: toggles archive flag, saves, syncs when online.  
- `addToShoppingList(_:)`: fetches/creates `ShoppingListEntry`, saves, pushes entry.  
- `StockListRow` exposes buttons via deterministic accessibility IDs (`EditButton_<id>`, etc.) for UI tests.

### 3.3 `StockItemSheet`
- `Mode.create` ensures `userId` exists, generates lowercase UUID.  
- `Mode.edit` preloads fields.  
- `save()` normalizes input, saves, optionally queues `addToShoppingList` when quantity hits zero, and pushes the item when not in local-only mode.

### 3.4 `ShoppingListView / ShoppingListRow`
- Queries `ShoppingListEntry` with `isDeleted == false`.  
- Maintains derived state (`completedEntries`) to show the “Save Receipt” toolbar action.  
- Quantity text field and completion toggle update SwiftData immediately and push to Supabase unless offline mode is enabled.

### 3.5 Receipt Flow
- `ShoppingListView` drives receipt creation.  
- `saveReceipt` constructs `Receipt` + `ReceiptItem` objects, increments related stock quantities, marks entries deleted, saves, then pushes receipt/items/stock updates asynchronously.

## 4. Business Rules
1. **Zero stock → shopping:** Any path reducing `quantityInStock` to zero must ensure `ShoppingListEntry` is present (create if missing, overwrite quantity with `quantityFullStock` if provided).
2. **Receipts replenish stock:** When a receipt is saved, associated `StockItem.quantityInStock` increases by `entry.desiredQuantity`.
3. **Soft deletes:** Inventory and shopping entries are never hard deleted; `isArchived` / `isDeleted` flags let the user recover state and keep auditability.
4. **Retry cap:** `PendingSync.retryCount` >= 5 removes the item from the queue to prevent infinite loops; errors are logged for manual review.

## 5. Testing Details
- **Unit:**  
  - `StockItemTests`: constructors, SwiftData persistence, quantity edge cases.  
  - `StockItemMappingTests`: `upsert` normalization, DTO round-trips.  
  - `OfflineQueueServiceTests`: happy-path sync, missing-entity error capture, retry cap enforcement.  
  - `StockListViewSyncTests`: interim coverage for save/sync flows (to be refactored with injectable logic).
- **UI:**  
  - `FamilyStockUITests`: Tab navigation, add/edit stock, add to shopping, mark complete, save receipts.  
  - Accessibility identifiers ensure stable element targeting.

## 6. Logging & Error Messaging
- Use emoji-prefixed `print` statements (`🔄`, `✅`, `❌`, `⚠️`) for sync lifecycle steps.  
- SwiftData failures call `assertionFailure` to surface issues during development.

## 7. Extensibility Considerations
- All models include `userId` to support shared households and multi-tenant reporting.  
- `SyncServiceProtocol` plus mock implementations (used in tests) pave the way for dependency injection.  
- `PendingSync`’s schema is generic enough to accommodate future entity types (e.g., meal plans, tasks).  
- Accessibility identifiers and deterministic IDs facilitate UI automation and could power analytics or feature flags later on.***
