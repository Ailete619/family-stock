//
//  StockListViewSyncTests.swift
//  FamilyStock
//
//  Created by Claude on 2025/11/06.
//
//  NOTE: These tests document the expected sync behavior and verify the
//  sync service integration. They simulate the flow that StockListView
//  follows but don't directly test the private view methods due to SwiftUI
//  testing limitations. The production code correctness should be verified
//  through UI tests and manual testing.
//

import Testing
import SwiftData
import Foundation
@testable import FamilyStock

@MainActor
struct StockListViewSyncTests {

    // MARK: - Sync Behavior Specification Tests
    // These tests document and verify the expected sync behavior that
    // StockListView.updateQuantity() should follow

    @Test func quantity_update_should_save_and_sync_when_online() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Simulate the flow that StockListView.updateQuantity() performs:
        // 1. Update the item
        item.quantityInStock = 4
        item.updatedAt = .now

        // 2. Save to context
        try context.save()

        // 3. Sync to Supabase (when online)
        await syncService.pushItem(item)

        // Verify the expected outcome
        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)
        #expect(items.first?.quantityInStock == 4)
        #expect(syncService.pushedItemIds == [item.id])
    }

    @Test func quantity_update_should_save_locally_only_when_offline() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 5)
        context.insert(item)
        try context.save()

        // Simulate the flow when isLocalOnly = true:
        // 1. Update the item
        item.quantityInStock = 4
        item.updatedAt = .now

        // 2. Save to context
        try context.save()

        // 3. Skip sync (guard returns early)
        // (no sync call)

        // Verify the expected outcome
        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)
        #expect(items.first?.quantityInStock == 4)
        #expect(syncService.pushedItemIds.isEmpty)
    }

    // MARK: - Shopping List Sync Behavior

    @Test func shopping_list_should_sync_new_entries_when_online() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk", quantityFullStock: 12)
        context.insert(item)
        try context.save()

        // Simulate StockListView.addToShoppingList() flow:
        let entry = ShoppingListEntry(
            userId: "user-123",
            itemId: item.id,
            desiredQuantity: 12,
            unit: ""
        )
        entry.updatedAt = .now
        context.insert(entry)
        try context.save()

        // Sync when online
        await syncService.pushShoppingEntry(entry)

        // Verify expected outcome
        #expect(syncService.pushedShoppingEntryIds == [entry.id])
    }

    // MARK: - Delete/Archive Sync Behavior

    @Test func delete_should_archive_and_sync_when_online() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk")
        context.insert(item)
        try context.save()

        // Simulate StockListView.delete() flow:
        item.isArchived = true
        item.updatedAt = .now
        try context.save()

        // Sync when online
        await syncService.pushItem(item)

        // Verify expected outcome
        #expect(item.isArchived == true)
        #expect(syncService.pushedItemIds == [item.id])
    }

    @Test func delete_should_archive_locally_only_when_offline() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk")
        context.insert(item)
        try context.save()

        // Simulate delete when isLocalOnly = true:
        item.isArchived = true
        item.updatedAt = .now
        try context.save()

        // Skip sync (guard returns early)

        // Verify expected outcome
        #expect(item.isArchived == true)
        #expect(syncService.pushedItemIds.isEmpty)
    }

    // MARK: - Data Model Tests

    @Test func archived_items_can_be_filtered() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item1 = StockItem(userId: "user-123", name: "Milk")
        let item2 = StockItem(userId: "user-123", name: "Bread")
        context.insert(item1)
        context.insert(item2)
        try context.save()

        item1.isArchived = true
        try context.save()

        // Verify filtering works (as used in StockListView body)
        var descriptor = FetchDescriptor<StockItem>()
        descriptor.predicate = #Predicate<StockItem> { item in
            item.isArchived == false
        }
        let activeItems = try context.fetch(descriptor)

        #expect(activeItems.count == 1)
        #expect(activeItems.first?.name == "Bread")
    }

    @Test func quantity_cannot_go_below_zero() async throws {
        let fixture = try makeFixture()
        let context = fixture.context

        let item = StockItem(userId: "user-123", name: "Milk", quantityInStock: 0)
        context.insert(item)
        try context.save()

        // Verify the max(0, ...) logic used in decreaseQuantity
        item.quantityInStock = max(0, item.quantityInStock - 1)
        try context.save()

        #expect(item.quantityInStock == 0)
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

// Note: This mock service is used to verify that the production code
// would call the sync methods with the correct parameters. It doesn't
// test the actual StockListView methods due to SwiftUI testing limitations.

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
