//
//  Item.swift.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftData
import Foundation

@Model
final class Item {
    @Attribute(.unique) var id: String
    var name: String
    var category: String?
    var updatedAt: Date
    var isDeleted: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String? = nil,
        updatedAt: Date = .now,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
}
