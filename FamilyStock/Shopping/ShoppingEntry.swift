//
//  ShoppingEntry.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftData
import Foundation

@Model
final class ShoppingEntry {
    @Attribute(.unique) var id: String
    var itemId: String                // FK to Item.id (simple for now)
    var desiredQuantity: Double
    var unit: String
    var note: String?
    var updatedAt: Date
    var isDeleted: Bool

    init(
        id: String = UUID().uuidString,
        itemId: String,
        desiredQuantity: Double = 1,
        unit: String = "pcs",
        note: String? = nil,
        updatedAt: Date = .now,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.itemId = itemId
        self.desiredQuantity = desiredQuantity
        self.unit = unit
        self.note = note
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
}
