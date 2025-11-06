//
//  OfflineQueueServiceTests.swift
//  FamilyStock
//
//  Created by ChatGPT on 2025/11/03.
//

import Testing
import SwiftData
import Foundation
@testable import FamilyStock

@MainActor
struct OfflineQueueServiceTests {
    @Test func queueSync_processes_stockItem_upsert() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let queue = fixture.queue
        let syncService = fixture.syncService

        let item = StockItem(userId: "user-123", name: "Milk")
        context.insert(item)
        try context.save()

        queue.queueSync(entityType: "StockItem", entityId: item.id, operation: "upsert")

        try await waitFor { syncService.pushedItemIds == [item.id] }

        #expect(syncService.pushedItemIds == [item.id])
        let pendingCount = try queue.getPendingSyncCount()
        #expect(pendingCount == 0)
    }

    @Test func processPendingSyncs_missing_stockItem_retains_entry() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let queue = fixture.queue

        queue.queueSync(entityType: "StockItem", entityId: "missing", operation: "upsert")

        try await waitFor {
            let descriptor = FetchDescriptor<PendingSync>()
            let pending = (try? context.fetch(descriptor))?.first
            return pending?.retryCount == 1 && pending?.errorMessage == "Item not found"
        }

        let descriptor = FetchDescriptor<PendingSync>()
        let pending = try context.fetch(descriptor)

        let entry = try #require(pending.first)
        #expect(entry.retryCount == 1)
        #expect(entry.errorMessage == "Item not found")
        let pendingCount = try queue.getPendingSyncCount()
        #expect(pendingCount == 1)
    }

    @Test func processPendingSyncs_drops_entries_after_max_retries() async throws {
        let fixture = try makeFixture()
        let context = fixture.context
        let queue = fixture.queue

        let stale = PendingSync(
            entityType: "StockItem",
            entityId: "missing",
            operation: "upsert",
            retryCount: 5
        )
        context.insert(stale)
        try context.save()

        let initialCount = try queue.getPendingSyncCount()
        #expect(initialCount == 1)

        await queue.processPendingSyncs()

        let remaining = try queue.getPendingSyncCount()
        #expect(remaining == 0)
    }
}

// MARK: - Test Fixtures

@MainActor
private func makeFixture() throws -> (context: ModelContext, queue: OfflineQueueService, syncService: MockSyncService) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: PendingSync.self,
        StockItem.self,
        ShoppingListEntry.self,
        Receipt.self,
        ReceiptItem.self,
        configurations: config
    )
    let context = ModelContext(container)
    let syncService = MockSyncService()
    let queue = OfflineQueueService(context: context, syncService: syncService)
    return (context, queue, syncService)
}

@MainActor
private final class MockSyncService: SyncServiceProtocol {
    private(set) var pushedItemIds: [String] = []
    private(set) var deletedItemIds: [String] = []
    private(set) var pushedShoppingEntryIds: [String] = []
    private(set) var deletedShoppingEntryIds: [String] = []
    private(set) var pushedReceiptIds: [String] = []
    private(set) var deletedReceiptIds: [String] = []

    func pushItem(_ item: StockItem) async {
        pushedItemIds.append(item.id)
    }

    func deleteItem(_ itemId: String) async {
        deletedItemIds.append(itemId)
    }

    func pushShoppingEntry(_ entry: ShoppingListEntry) async {
        pushedShoppingEntryIds.append(entry.id)
    }

    func deleteShoppingEntry(_ entryId: String) async {
        deletedShoppingEntryIds.append(entryId)
    }

    func pushReceipt(_ receipt: Receipt) async {
        pushedReceiptIds.append(receipt.id)
    }

    func deleteReceipt(_ receiptId: String) async {
        deletedReceiptIds.append(receiptId)
    }
}

private struct DummyItemRepository: ItemRepository {
    func fetchUpdatedSince(_ date: Date?) async throws -> [StockItemDTO] { [] }
    func upsert(_ item: StockItemDTO) async throws -> StockItemDTO { item }
    func delete(id: String) async throws {}
}

private struct DummyShoppingRepository: ShoppingListEntryRepository {
    func fetchUpdatedSince(_ date: Date?) async throws -> [ShoppingListEntryDTO] { [] }
    func upsert(_ entry: ShoppingListEntryDTO) async throws -> ShoppingListEntryDTO { entry }
    func delete(id: String) async throws {}
}

private struct DummyReceiptRepository: ReceiptRepository {
    func fetchUpdatedSince(_ date: Date?) async throws -> ([ReceiptDTO], [ReceiptItemDTO]) { ([], []) }
    func upsert(_ receipt: ReceiptDTO, items: [ReceiptItemDTO]) async throws -> ReceiptDTO { receipt }
    func delete(id: String) async throws {}
}

// MARK: - Helpers

@MainActor
private func waitFor(
    timeout: TimeInterval = 1,
    checkInterval: UInt64 = 10_000_000,
    condition: @escaping @MainActor () -> Bool
) async throws {
    let attempts = Int(timeout * 1_000_000_000 / Double(checkInterval))

    for _ in 0..<attempts {
        if condition() {
            return
        }
        try await Task.sleep(nanoseconds: checkInterval)
    }

    Issue.record("Condition was not met within \(timeout) seconds")
    throw WaitTimeoutError()
}

private struct WaitTimeoutError: Error {}
