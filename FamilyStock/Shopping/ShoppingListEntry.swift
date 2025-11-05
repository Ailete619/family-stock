//
//  ShoppingListEntry.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftData
import Foundation

@Model
final class ShoppingListEntry {
    @Attribute(.unique) var id: String
    var userId: String
    var itemId: String                // FK to Item.id (simple for now)
    var desiredQuantity: Double
    var unit: String
    var note: String?
    var updatedAt: Date
    var isDeleted: Bool
    var isCompleted: Bool = false

    init(
        id: String = UUID().uuidString.lowercased(),
        userId: String,
        itemId: String,
        desiredQuantity: Double = 1,
        unit: String = "pcs",
        note: String? = nil,
        updatedAt: Date = .now,
        isDeleted: Bool = false,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.itemId = itemId
        self.desiredQuantity = desiredQuantity
        self.unit = unit
        self.note = note
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.isCompleted = isCompleted
    }
}
