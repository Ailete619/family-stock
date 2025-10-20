//
//  ReceiptItem.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/17.
//

import SwiftData
import Foundation

@Model
final class ReceiptItem {
    @Attribute(.unique) var id: String
    var itemName: String
    var quantity: Double
    var receipt: Receipt?

    init(
        id: String = UUID().uuidString,
        itemName: String,
        quantity: Double,
        receipt: Receipt? = nil
    ) {
        self.id = id
        self.itemName = itemName
        self.quantity = quantity
        self.receipt = receipt
    }
}
