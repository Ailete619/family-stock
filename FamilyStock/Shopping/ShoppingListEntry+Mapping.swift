//
//  ShoppingListEntry+Mapping.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import SwiftData
import Foundation

extension ShoppingListEntry {
    static func upsert(from dto: ShoppingListEntryDTO, in ctx: ModelContext) throws {
        // Normalize ID to lowercase for consistent storage
        let normalizedId = dto.id.lowercased()
        let normalizedItemId = dto.item_id.lowercased()

        // Fetch existing entry by normalized ID
        let predicate = #Predicate<ShoppingListEntry> { entry in
            entry.id == normalizedId
        }
        var descriptor = FetchDescriptor<ShoppingListEntry>(predicate: predicate)
        descriptor.fetchLimit = 1

        let existingEntries = try ctx.fetch(descriptor)

        if let existing = existingEntries.first {
            // Update existing entry
            existing.userId = dto.user_id
            existing.itemId = normalizedItemId
            existing.desiredQuantity = dto.desired_quantity
            existing.unit = dto.unit
            existing.note = dto.note
            existing.updatedAt = dto.updated_at
            existing.isDeleted = dto.is_deleted
            existing.isCompleted = dto.is_completed
        } else {
            // Create new entry with normalized IDs
            let entry = ShoppingListEntry(
                id: normalizedId,
                userId: dto.user_id,
                itemId: normalizedItemId,
                desiredQuantity: dto.desired_quantity,
                unit: dto.unit,
                note: dto.note,
                updatedAt: dto.updated_at,
                isDeleted: dto.is_deleted,
                isCompleted: dto.is_completed
            )
            ctx.insert(entry)
        }
    }

    func toDTO() -> ShoppingListEntryDTO {
        ShoppingListEntryDTO(
            id: id,
            user_id: userId,
            item_id: itemId,
            desired_quantity: desiredQuantity,
            unit: unit,
            note: note,
            updated_at: updatedAt,
            is_deleted: isDeleted,
            is_completed: isCompleted
        )
    }
}
