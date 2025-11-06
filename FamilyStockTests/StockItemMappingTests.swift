//
//  StockItemMappingTests.swift
//  FamilyStock
//
//  Created by ChatGPT on 2025/11/03.
//

import Testing
import SwiftData
import Foundation
@testable import FamilyStock

@MainActor
struct StockItemMappingTests {
    @Test func upsert_inserts_and_normalizes_identifiers() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        let dto = StockItemDTO(
            id: "ABC-123",
            user_id: "user-123",
            name: "Milk",
            category: "Dairy",
            updated_at: Date(timeIntervalSince1970: 123),
            is_archived: false,
            quantity_in_stock: 2,
            quantity_full_stock: 5
        )

        try StockItem.upsert(from: dto, in: context)
        try context.save()

        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.id == "abc-123")
        #expect(item.userId == "user-123")
        #expect(item.name == "Milk")
        #expect(item.category == "Dairy")
        #expect(item.updatedAt == Date(timeIntervalSince1970: 123))
        #expect(item.quantityInStock == 2)
        #expect(item.quantityFullStock == 5)
    }

    @Test func upsert_updates_existing_entry() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        let original = StockItem(
            id: "abc-123",
            userId: "user-123",
            name: "Milk",
            category: "Dairy",
            updatedAt: Date(timeIntervalSince1970: 100),
            isArchived: false,
            quantityInStock: 1,
            quantityFullStock: 4
        )

        context.insert(original)
        try context.save()

        let updatedDTO = StockItemDTO(
            id: "ABC-123",
            user_id: "user-456",
            name: "Oat Milk",
            category: "Vegan",
            updated_at: Date(timeIntervalSince1970: 200),
            is_archived: true,
            quantity_in_stock: 3,
            quantity_full_stock: 10
        )

        try StockItem.upsert(from: updatedDTO, in: context)
        try context.save()

        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.id == "abc-123")
        #expect(item.userId == "user-456")
        #expect(item.name == "Oat Milk")
        #expect(item.category == "Vegan")
        #expect(item.updatedAt == Date(timeIntervalSince1970: 200))
        #expect(item.isArchived == true)
        #expect(item.quantityInStock == 3)
        #expect(item.quantityFullStock == 10)
    }

    @Test func toDTO_round_trips_core_fields() {
        let item = StockItem(
            id: "abc-123",
            userId: "user-123",
            name: "Milk",
            category: "Dairy",
            updatedAt: Date(timeIntervalSince1970: 123),
            isArchived: true,
            quantityInStock: 2,
            quantityFullStock: 5
        )

        let dto = item.toDTO()

        #expect(dto.id == "abc-123")
        #expect(dto.user_id == "user-123")
        #expect(dto.name == "Milk")
        #expect(dto.category == "Dairy")
        #expect(dto.updated_at == Date(timeIntervalSince1970: 123))
        #expect(dto.is_archived == true)
        #expect(dto.quantity_in_stock == 2)
        #expect(dto.quantity_full_stock == 5)
    }
}
