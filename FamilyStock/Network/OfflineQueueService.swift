//
//  OfflineQueueService.swift
//  FamilyStock
//
//  Created by Claude on 2025/11/02.
//

import SwiftData
import Foundation

@MainActor
final class OfflineQueueService {
    private let context: ModelContext
    private let syncService: SyncServiceProtocol
    private var isProcessing = false

    init(context: ModelContext, syncService: SyncServiceProtocol) {
        self.context = context
        self.syncService = syncService
    }

    // MARK: - Queue Management

    /// Add a pending sync operation to the queue
    func queueSync(entityType: String, entityId: String, operation: String) {
        let pending = PendingSync(
            entityType: entityType,
            entityId: entityId,
            operation: operation
        )
        context.insert(pending)

        do {
            try context.save()
            print("📝 Queued sync: \(entityType) \(entityId)")

            // Try to process immediately if online
            Task {
                await processPendingSyncs()
            }
        } catch {
            print("❌ Failed to queue sync: \(error)")
        }
    }

    /// Process all pending syncs in the queue
    func processPendingSyncs() async {
        // Prevent concurrent processing
        guard !isProcessing else {
            print("⏳ Already processing pending syncs")
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // Fetch all pending syncs, oldest first
            let descriptor = FetchDescriptor<PendingSync>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let pendingSyncs = try context.fetch(descriptor)

            guard !pendingSyncs.isEmpty else {
                print("✅ No pending syncs")
                return
            }

            print("🔄 Processing \(pendingSyncs.count) pending syncs")

            for pending in pendingSyncs {
                await processSingleSync(pending)
            }

            print("✅ Finished processing pending syncs")
        } catch {
            print("❌ Failed to fetch pending syncs: \(error)")
        }
    }

    private func processSingleSync(_ pending: PendingSync) async {
        // Skip if too many retries - REMOVE from queue
        guard pending.retryCount < 5 else {
            print("⚠️ Max retries reached for \(pending.entityType) \(pending.entityId), removing from queue")
            context.delete(pending)
            try? context.save()
            return
        }

        pending.lastAttempt = .now
        pending.retryCount += 1

        // Save retry count increment BEFORE attempting sync
        do {
            try context.save()
        } catch {
            print("❌ Failed to save retry count: \(error)")
        }

        do {
            // Find the actual entity and sync it based on operation type
            switch (pending.entityType, pending.operation) {
            case ("StockItem", "delete"):
                await syncService.deleteItem(pending.entityId)
            case ("StockItem", _):
                try await syncStockItem(pending.entityId)
            case ("ShoppingListEntry", "delete"):
                await syncService.deleteShoppingEntry(pending.entityId)
            case ("ShoppingListEntry", _):
                try await syncShoppingEntry(pending.entityId)
            case ("Receipt", "delete"):
                await syncService.deleteReceipt(pending.entityId)
            case ("Receipt", _):
                try await syncReceipt(pending.entityId)
            default:
                print("⚠️ Unknown entity type: \(pending.entityType), removing from queue")
                context.delete(pending)
                try? context.save()
                return
            }

            // Success - remove from queue
            context.delete(pending)
            try context.save()
            print("✅ Synced \(pending.entityType) \(pending.entityId)")
        } catch {
            // Failed - update error message but DON'T delete (will retry later)
            pending.errorMessage = error.localizedDescription
            try? context.save()
            print("❌ Failed to sync \(pending.entityType) \(pending.entityId) (attempt \(pending.retryCount)/5): \(error)")
        }
    }

    // MARK: - Entity Sync

    private func syncStockItem(_ itemId: String) async throws {
        let predicate = #Predicate<StockItem> { item in
            item.id == itemId
        }
        var descriptor = FetchDescriptor<StockItem>(predicate: predicate)
        descriptor.fetchLimit = 1

        let items = try context.fetch(descriptor)
        guard let item = items.first else {
            throw NSError(domain: "OfflineQueue", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
        }

        await syncService.pushItem(item)
    }

    private func syncShoppingEntry(_ entryId: String) async throws {
        let predicate = #Predicate<ShoppingListEntry> { entry in
            entry.id == entryId
        }
        var descriptor = FetchDescriptor<ShoppingListEntry>(predicate: predicate)
        descriptor.fetchLimit = 1

        let entries = try context.fetch(descriptor)
        guard let entry = entries.first else {
            throw NSError(domain: "OfflineQueue", code: 404, userInfo: [NSLocalizedDescriptionKey: "Entry not found"])
        }

        await syncService.pushShoppingEntry(entry)
    }

    private func syncReceipt(_ receiptId: String) async throws {
        let predicate = #Predicate<Receipt> { receipt in
            receipt.id == receiptId
        }
        var descriptor = FetchDescriptor<Receipt>(predicate: predicate)
        descriptor.fetchLimit = 1

        let receipts = try context.fetch(descriptor)
        guard let receipt = receipts.first else {
            throw NSError(domain: "OfflineQueue", code: 404, userInfo: [NSLocalizedDescriptionKey: "Receipt not found"])
        }

        await syncService.pushReceipt(receipt)
    }

    // MARK: - Queue Status

    func getPendingSyncCount() throws -> Int {
        let descriptor = FetchDescriptor<PendingSync>()
        return try context.fetchCount(descriptor)
    }

    func clearFailedSyncs() throws {
        let descriptor = FetchDescriptor<PendingSync>()
        let allPending = try context.fetch(descriptor)

        for pending in allPending where pending.retryCount >= 5 {
            context.delete(pending)
        }

        try context.save()
    }
}
