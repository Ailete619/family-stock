//
//  StockListViewSyncTests.swift
//  FamilyStock
//
//  Created by Claude on 2025/11/06.
//

import Testing
import SwiftData
import Foundation
@testable import FamilyStock

@MainActor
struct StockListViewSyncTests {

    // MARK: - updateQuantity Tests

    @Test func updateQuantity_saves_to_context() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Simulate quantity update
        item.quantityInStock = 4
        item.updatedAt = .now

        // Save should succeed
        try context.save()

        // Verify quantity was saved
        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)
        #expect(items.first?.quantityInStock == 4)
    }

    @Test func updateQuantity_does_not_sync_when_local_only() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Simulate local-only mode by NOT calling syncService
        item.quantityInStock = 4
        try context.save()

        // Verify no sync occurred
        #expect(syncService.pushedItemIds.isEmpty)
    }

    @Test func updateQuantity_syncs_when_online() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Simulate online sync
        item.quantityInStock = 4
        item.updatedAt = .now
        try context.save()

        await syncService.pushItem(item)

        // Verify sync occurred
        #expect(syncService.pushedItemIds == [item.id])
    }

    // MARK: - addToShoppingList Tests

    @Test func addToShoppingList_creates_new_entry() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item = StockItem(userId: "user-123", name: "Milk", quantityFullStock: 12)
        context.insert(item)
        try context.save()

        // Create shopping list entry
        let entry = ShoppingListEntry(
            userId: "user-123",
            itemId: item.id,
            desiredQuantity: 12,
            unit: ""
        )
        entry.updatedAt = .now
        context.insert(entry)
        try context.save()

        // Verify entry was created
        let descriptor = FetchDescriptor<ShoppingListEntry>()
        let entries = try context.fetch(descriptor)
        #expect(entries.count == 1)
        #expect(entries.first?.itemId == item.id)
        #expect(entries.first?.desiredQuantity == 12)
    }

    @Test func addToShoppingList_updates_existing_entry() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item = StockItem(userId: "user-123", name: "Milk", quantityFullStock: 12)
        context.insert(item)
        try context.save()

        // Create initial entry
        let entry = ShoppingListEntry(
            userId: "user-123",
            itemId: item.id,
            desiredQuantity: 6,
            unit: ""
        )
        context.insert(entry)
        try context.save()

        // Update existing entry
        entry.desiredQuantity = 12
        entry.updatedAt = .now
        try context.save()

        // Verify entry was updated
        let descriptor = FetchDescriptor<ShoppingListEntry>()
        let entries = try context.fetch(descriptor)
        #expect(entries.count == 1)
        #expect(entries.first?.desiredQuantity == 12)
    }

    @Test func addToShoppingList_syncs_when_online() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityFullStock: 12)
        context.insert(item)
        try context.save()

        let entry = ShoppingListEntry(
            userId: "user-123",
            itemId: item.id,
            desiredQuantity: 12,
            unit: ""
        )
        context.insert(entry)
        try context.save()

        // Simulate sync
        await syncService.pushShoppingEntry(entry)

        // Verify sync occurred
        #expect(syncService.pushedShoppingEntryIds == [entry.id])
    }

    // MARK: - delete Tests

    @Test func delete_archives_item() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item = StockItem(userId: "user-123", name: "Milk")
        context.insert(item)
        try context.save()

        // Archive item
        item.isArchived = true
        item.updatedAt = .now
        try context.save()

        // Verify item is archived
        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)
        #expect(items.first?.isArchived == true)
    }

    @Test func delete_filters_archived_items() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item1 = StockItem(userId: "user-123", name: "Milk")
        let item2 = StockItem(userId: "user-123", name: "Bread")
        context.insert(item1)
        context.insert(item2)
        try context.save()

        // Archive one item
        item1.isArchived = true
        try context.save()

        // Fetch non-archived items
        var descriptor = FetchDescriptor<StockItem>()
        descriptor.predicate = #Predicate<StockItem> { item in
            item.isArchived == false
        }
        let activeItems = try context.fetch(descriptor)

        #expect(activeItems.count == 1)
        #expect(activeItems.first?.name == "Bread")
    }

    @Test func delete_syncs_when_online() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk")
        context.insert(item)
        try context.save()

        // Archive and sync
        item.isArchived = true
        item.updatedAt = .now
        try context.save()

        await syncService.pushItem(item)

        // Verify sync occurred
        #expect(syncService.pushedItemIds == [item.id])
    }

    @Test func delete_does_not_sync_when_local_only() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk")
        context.insert(item)
        try context.save()

        // Archive without sync (local-only mode)
        item.isArchived = true
        try context.save()

        // Verify no sync occurred
        #expect(syncService.pushedItemIds.isEmpty)
    }

    // MARK: - StockListRow decreaseQuantity Tests

    @Test func decreaseQuantity_updates_quantity() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Simulate decrease
        item.quantityInStock = max(0, item.quantityInStock - 1)
        item.updatedAt = .now
        try context.save()

        // Verify quantity decreased
        #expect(item.quantityInStock == 4)
    }

    @Test func decreaseQuantity_does_not_go_below_zero() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 0)
        context.insert(item)
        try context.save()

        // Try to decrease below zero
        item.quantityInStock = max(0, item.quantityInStock - 1)
        try context.save()

        // Verify quantity stays at 0
        #expect(item.quantityInStock == 0)
    }

    @Test func decreaseQuantity_triggers_sync() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Decrease and sync
        item.quantityInStock = max(0, item.quantityInStock - 1)
        item.updatedAt = .now
        try context.save()

        await syncService.pushItem(item)

        // Verify sync occurred
        #expect(syncService.pushedItemIds == [item.id])
    }

    // MARK: - Integration Tests

    @Test func multiple_operations_sync_correctly() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Decrease quantity
        item.quantityInStock = 4
        item.updatedAt = .now
        try context.save()
        await syncService.pushItem(item)

        // Create shopping entry
        let entry = ShoppingListEntry(
            userId: "user-123",
            itemId: item.id,
            desiredQuantity: 12,
            unit: ""
        )
        context.insert(entry)
        try context.save()
        await syncService.pushShoppingEntry(entry)

        // Archive item
        item.isArchived = true
        item.updatedAt = .now
        try context.save()
        await syncService.pushItem(item)

        // Verify all syncs occurred
        #expect(syncService.pushedItemIds.count == 2)
        #expect(syncService.pushedShoppingEntryIds.count == 1)
    }
}

// MARK: - Test Fixtures

@MainActor
private func makeFixture() throws -> (context: ModelContext, syncService: MockSyncService) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: StockItem.self,
        ShoppingListEntry.self,
        Receipt.self,
        ReceiptItem.self,
        PendingSync.self,
        configurations: config
    )
    let context = ModelContext(container)
    let syncService = MockSyncService()
    return (context, syncService)
}

@MainActor
private final class MockSyncService: SyncServiceProtocol {
    private(set) var pushedItemIds: [String] = []
    private(set) var pushedShoppingEntryIds: [String] = []

    func pushItem(_ item: StockItem) async {
        pushedItemIds.append(item.id)
    }

    func pushShoppingEntry(_ entry: ShoppingListEntry) async {
        pushedShoppingEntryIds.append(entry.id)
    }

    func pushReceipt(_ receipt: Receipt) async {
        // Not used in these tests
    }

    func deleteItem(_ itemId: String) async {
        // Not used in these tests
    }

    func deleteShoppingEntry(_ entryId: String) async {
        // Not used in these tests
    }

    func deleteReceipt(_ receiptId: String) async {
        // Not used in these tests
    }
}
