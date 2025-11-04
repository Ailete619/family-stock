//
//  DTOs.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation

struct StockItemDTO: Codable, Identifiable {
    var id: String
    var user_id: String
    var name: String
    var category: String?
    var updated_at: Date
    var is_archived: Bool
    var quantity_in_stock: Double
    var quantity_full_stock: Double
}

struct ShoppingListEntryDTO: Codable, Identifiable {
    var id: String
    var user_id: String
    var item_id: String
    var desired_quantity: Double
    var unit: String
    var note: String?
    var updated_at: Date
    var is_deleted: Bool
    var is_completed: Bool
}

struct ReceiptDTO: Codable, Identifiable {
    var id: String
    var user_id: String
    var shop_name: String
    var timestamp: Date
    var amount: Double?
}

struct ReceiptItemDTO: Codable, Identifiable {
    var id: String
    var receipt_id: String
    var item_name: String
    var quantity: Double
}
