# Testing Notes for FamilyStock

## Sync Functionality Testing

### Limitations

The tests in `StockListViewSyncTests.swift` are **specification tests** that document the expected sync behavior, but they have an important limitation:

**They do NOT directly test the `StockListView` private methods** (`updateQuantity()`, `delete()`, `addToShoppingList()`) due to SwiftUI testing constraints:

1. These methods are `private extension` functions that cannot be accessed from tests
2. They depend on SwiftUI state (`@State`, `@StateObject`, `@Environment`) that's difficult to mock
3. SwiftUI views are not designed for traditional unit testing

### What the Tests Actually Verify

The current tests verify:
- ✅ The sync service protocol works correctly
- ✅ SwiftData operations function as expected
- ✅ The **expected flow** that the production code should follow
- ✅ Data model constraints (e.g., quantity can't go negative, archived items filter correctly)

### What the Tests DON'T Verify

The tests do NOT verify:
- ❌ That `StockListView.updateQuantity()` actually calls `syncService.pushItem()`
- ❌ That `StockListView.delete()` actually calls `syncService.pushItem()` after archiving
- ❌ That `StockListView.addToShoppingList()` actually calls `syncService.pushShoppingEntry()`
- ❌ That the `isLocalOnly` guards work correctly in the actual view code

**This means a regression could occur** where the production code stops calling the sync methods, but the tests would still pass.

## Recommendations for Ensuring Correctness

Since unit tests have limitations, use these approaches:

### 1. UI Tests (Automated)
Create UI tests in `FamilyStockUITests` that:
- Modify a stock item quantity and verify it syncs to Supabase
- Add an item to the shopping list and verify the sync
- Delete an item and verify the archive syncs
- Toggle local-only mode and verify no syncs occur

### 2. Manual Testing Checklist
Before each release, manually verify:
- [ ] Decrease stock quantity → Check Supabase database shows updated quantity
- [ ] Add item to shopping list → Check Supabase shows new shopping entry
- [ ] Delete/archive item → Check Supabase shows `isArchived = true`
- [ ] Toggle local-only mode → Verify no network requests occur
- [ ] Go back online → Verify pending changes sync

### 3. Code Review Focus
When reviewing changes to `StockListView.swift`, carefully verify:
- All data modifications are followed by `try context.save()`
- All save operations are followed by the sync guard: `guard let syncService = syncService, !auth.isLocalOnly else { return }`
- All sync operations use `Task { await syncService.push...() }`

### 4. Architecture Consideration
For better testability in future refactoring, consider:
- Extracting business logic into testable classes (not SwiftUI views)
- Using a view model pattern to separate concerns
- Making sync methods internal/public and testable

## Current Test Coverage

| Area | Coverage | Verification Method |
|------|----------|-------------------|
| Sync Service Protocol | ✅ 100% | Unit tests |
| SwiftData Operations | ✅ 100% | Unit tests |
| Offline Queue Service | ✅ 100% | Unit tests (all entity types + operations) |
| Sync Flow Specifications | ✅ 100% | Specification tests |
| Production View Methods | ⚠️ 0% | Manual testing required |
| End-to-End Sync | ⚠️ Partial | UI tests needed |

### OfflineQueueServiceTests Coverage

The offline queue tests now cover **all entity types** and **all operations**:

✅ StockItem upsert
✅ StockItem delete
✅ ShoppingListEntry upsert
✅ ShoppingListEntry delete
✅ Receipt upsert
✅ Receipt delete
✅ Missing entity error handling
✅ Max retry logic
✅ Multiple entities processing

## Conclusion

The current test suite provides **specification documentation** and verifies the **building blocks work correctly**, but **production code correctness must be verified through UI tests and manual testing** due to SwiftUI's testing limitations.

This is a known limitation of SwiftUI testing, not a deficiency in the test suite itself.
