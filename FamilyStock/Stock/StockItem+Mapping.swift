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
        // Fetch existing item by ID using a predicate
        let predicate = #Predicate<StockItem> { item in
            item.id == dto.id
        }
        var descriptor = FetchDescriptor<StockItem>(predicate: predicate)
        descriptor.fetchLimit = 1

        let existingItems = try ctx.fetch(descriptor)

        if let existing = existingItems.first {
            // Update existing item
            existing.userId = dto.user_id
            existing.name = dto.name
            existing.category = dto.category
            existing.updatedAt = dto.updated_at
            existing.isArchived = dto.is_archived
            existing.quantityInStock = dto.quantity_in_stock
            existing.quantityFullStock = dto.quantity_full_stock
        } else {
            // Create new item
            let s = StockItem(
                id: dto.id,
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
