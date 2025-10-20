//
//  Receipt.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/17.
//

import SwiftData
import Foundation

@Model
final class Receipt {
    @Attribute(.unique) var id: String
    var shopName: String
    var timestamp: Date
    var amount: Double?
    @Relationship(deleteRule: .cascade) var items: [ReceiptItem]

    init(
        id: String = UUID().uuidString,
        shopName: String,
        timestamp: Date = .now,
        amount: Double? = nil,
        items: [ReceiptItem] = []
    ) {
        self.id = id
        self.shopName = shopName
        self.timestamp = timestamp
        self.amount = amount
        self.items = items
    }
}
