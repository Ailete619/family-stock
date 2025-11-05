//
//  PendingSync.swift
//  FamilyStock
//
//  Created by Claude on 2025/11/02.
//

import SwiftData
import Foundation

@Model
final class PendingSync {
    @Attribute(.unique) var id: String
    var entityType: String // "StockItem", "ShoppingListEntry", "Receipt"
    var entityId: String
    var operation: String // "create", "update", "delete"
    var createdAt: Date
    var retryCount: Int = 0
    var lastAttempt: Date?
    var errorMessage: String?

    init(
        id: String = UUID().uuidString,
        entityType: String,
        entityId: String,
        operation: String,
        createdAt: Date = .now,
        retryCount: Int = 0,
        lastAttempt: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
        self.errorMessage = errorMessage
    }
}
