//
//  StockItem+Mapping.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import SwiftData
import Foundation

extension StockItem {
    static func upsert(from dto: StockItemDTO, in ctx: ModelContext) throws {
        // Normalize ID to lowercase for consistent storage
        // (Supabase returns UUIDs in lowercase, we need to match)
        let normalizedId = dto.id.lowercased()

        // Fetch existing item by normalized ID
        let predicate = #Predicate<StockItem> { item in
            item.id == normalizedId
        }
        var descriptor = FetchDescriptor<StockItem>(predicate: predicate)
        let existingItems = try ctx.fetch(descriptor)

        if existingItems.count > 1 {
            print("⚠️ WARNING: Found \(existingItems.count) items with ID \(dto.id)")
        }

        if let existing = existingItems.first {
            // Update existing item
            print("📝 Updating existing item: \(dto.name) (id: \(normalizedId))")
            existing.userId = dto.user_id
            existing.name = dto.name
            existing.category = dto.category
            existing.updatedAt = dto.updated_at
            existing.isArchived = dto.is_archived
            existing.quantityInStock = dto.quantity_in_stock
            existing.quantityFullStock = dto.quantity_full_stock
        } else {
            // Create new item with normalized (lowercase) ID
            print("➕ Creating new item: \(dto.name) (id: \(normalizedId))")
            let s = StockItem(
                id: normalizedId,  // Use normalized ID
                userId: dto.user_id,
                name: dto.name,
                category: dto.category,
                updatedAt: dto.updated_at,
                isArchived: dto.is_archived,
                quantityInStock: dto.quantity_in_stock,
                quantityFullStock: dto.quantity_full_stock
            )
            ctx.insert(s)
        }
    }

    func toDTO() -> StockItemDTO {
        StockItemDTO(
            id: id,
            user_id: userId,
            name: name,
            category: category,
            updated_at: updatedAt,
            is_archived: isArchived,
            quantity_in_stock: quantityInStock,
            quantity_full_stock: quantityFullStock
        )
    }
}
