//
//  SyncService.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import SwiftData
import SwiftUI

@MainActor
final class SyncService {
    private let itemRepo: ItemRepository
    private let shoppingRepo: ShoppingListEntryRepository
    private let receiptRepo: ReceiptRepository
    private let context: ModelContext

    @AppStorage("lastPullItems") private var lastPullItemsISO: String = ""
    @AppStorage("lastPullShopping") private var lastPullShoppingISO: String = ""
    @AppStorage("lastPullReceipts") private var lastPullReceiptsISO: String = ""

    init(
        itemRepo: ItemRepository = SupabaseItemRepository(),
        shoppingRepo: ShoppingListEntryRepository = SupabaseShoppingListEntryRepository(),
        receiptRepo: ReceiptRepository = SupabaseReceiptRepository(),
        context: ModelContext
    ) {
        self.itemRepo = itemRepo
        self.shoppingRepo = shoppingRepo
        self.receiptRepo = receiptRepo
        self.context = context
    }

    /// Pull all entities from Supabase
    func pullAll() async {
        await pullItems()
        await pullShopping()
        await pullReceipts()
    }

    /// Pull only stock items
    func pullItems() async {
        do {
            let lastDate = ISO8601DateFormatter().date(from: lastPullItemsISO)
            let dtos = try await itemRepo.fetchUpdatedSince(lastDate)
            for dto in dtos { try StockItem.upsert(from: dto, in: context) }
            try context.save()
            lastPullItemsISO = ISO8601DateFormatter().string(from: .now)
        } catch {
            print("Pull items failed:", error)
        }
    }

    /// Pull only shopping entries
    func pullShopping() async {
        do {
            let lastDate = ISO8601DateFormatter().date(from: lastPullShoppingISO)
            let dtos = try await shoppingRepo.fetchUpdatedSince(lastDate)
            for dto in dtos { try ShoppingListEntry.upsert(from: dto, in: context) }
            try context.save()
            lastPullShoppingISO = ISO8601DateFormatter().string(from: .now)
        } catch {
            print("Pull shopping failed:", error)
        }
    }

    /// Pull only receipts and their items
    func pullReceipts() async {
        do {
            let lastDate = ISO8601DateFormatter().date(from: lastPullReceiptsISO)
            let (receiptDTOs, itemDTOs) = try await receiptRepo.fetchUpdatedSince(lastDate)

            // Group items by receipt ID
            let itemsByReceipt = Dictionary(grouping: itemDTOs, by: { $0.receipt_id })

            // Upsert receipts with their items
            for receiptDTO in receiptDTOs {
                let items = itemsByReceipt[receiptDTO.id] ?? []
                try Receipt.upsert(from: receiptDTO, items: items, in: context)
            }

            try context.save()
            lastPullReceiptsISO = ISO8601DateFormatter().string(from: .now)
        } catch {
            print("Pull receipts failed:", error)
        }
    }

    /// Push a single stock item to Supabase
    func pushItem(_ item: StockItem) async {
        do {
            let dto = item.toDTO()
            let _ = try await itemRepo.upsert(dto)
            print("✅ Pushed item: \(item.name)")
        } catch {
            print("Push item failed:", error)
        }
    }

    /// Push a single shopping entry to Supabase
    func pushShoppingEntry(_ entry: ShoppingListEntry) async {
        do {
            let dto = entry.toDTO()
            let _ = try await shoppingRepo.upsert(dto)
            print("✅ Pushed shopping entry")
        } catch {
            print("Push shopping entry failed:", error)
        }
    }

    /// Push a single receipt with its items to Supabase
    func pushReceipt(_ receipt: Receipt) async {
        do {
            let receiptDTO = receipt.toDTO()
            let itemDTOs = receipt.itemsToDTOs()
            let _ = try await receiptRepo.upsert(receiptDTO, items: itemDTOs)
            print("✅ Pushed receipt: \(receipt.shopName)")
        } catch {
            print("Push receipt failed:", error)
        }
    }
}
