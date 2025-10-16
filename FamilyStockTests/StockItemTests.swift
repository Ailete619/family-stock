//
//  StockItemTests.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import Testing
import SwiftData
import Foundation
@testable import FamilyStock

struct StockItemTests {

    // MARK: - Model Creation Tests

    @Test func stockItem_initializes_with_defaults() {
        let item = StockItem(name: "Milk")

        #expect(item.name == "Milk")
        #expect(item.category == nil)
        #expect(item.isArchived == false)
        #expect(item.quantityOnHand == 0)
        #expect(!item.id.isEmpty)
    }

    @Test func stockItem_initializes_with_category() {
        let item = StockItem(name: "Milk", category: "Dairy")

        #expect(item.name == "Milk")
        #expect(item.category == "Dairy")
        #expect(item.isArchived == false)
    }

    @Test func stockItem_initializes_with_quantity() {
        let item = StockItem(name: "Milk", quantityOnHand: 2.5)

        #expect(item.name == "Milk")
        #expect(item.quantityOnHand == 2.5)
    }

    // MARK: - SwiftData Persistence Tests

    @Test func stockItem_can_be_inserted_and_fetched() throws {
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Insert item
        let item = StockItem(name: "Test Item", category: "Test Category")
        context.insert(item)
        try context.save()

        // Fetch items
        let descriptor = FetchDescriptor<StockItem>()
        let fetchedItems = try context.fetch(descriptor)

        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.name == "Test Item")
        #expect(fetchedItems.first?.category == "Test Category")
    }

    @Test func stockItem_persists_after_save() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Insert and save
        let item = StockItem(name: "Persistent Item")
        let itemId = item.id
        context.insert(item)
        try context.save()

        // Create new context to simulate fresh fetch
        let newContext = ModelContext(container)
        let descriptor = FetchDescriptor<StockItem>()
        let fetchedItems = try newContext.fetch(descriptor)

        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.id == itemId)
        #expect(fetchedItems.first?.name == "Persistent Item")
    }

    @Test func stockItem_can_be_updated() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Insert item
        let item = StockItem(name: "Original Name")
        context.insert(item)
        try context.save()

        // Update item
        item.name = "Updated Name"
        item.quantityOnHand = 5.0
        try context.save()

        // Fetch and verify
        let descriptor = FetchDescriptor<StockItem>()
        let fetchedItems = try context.fetch(descriptor)

        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.name == "Updated Name")
        #expect(fetchedItems.first?.quantityOnHand == 5.0)
    }

    @Test func stockItem_soft_delete_works() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Insert item
        let item = StockItem(name: "To Delete")
        context.insert(item)
        try context.save()

        // Soft delete
        item.isArchived = true
        try context.save()

        // Fetch all items (including deleted)
        let allDescriptor = FetchDescriptor<StockItem>()
        let allItems = try context.fetch(allDescriptor)
        #expect(allItems.count == 1)
        #expect(allItems.first?.isArchived == true)

        // Fetch only non-deleted items
        var activeDescriptor = FetchDescriptor<StockItem>()
        activeDescriptor.predicate = #Predicate<StockItem> { item in
            item.isArchived == false
        }
        let activeItems = try context.fetch(activeDescriptor)
        #expect(activeItems.count == 0)
    }

    @Test func multiple_stockItems_can_be_stored() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Insert multiple items
        let items = [
            StockItem(name: "Milk", category: "Dairy"),
            StockItem(name: "Bread", category: "Bakery"),
            StockItem(name: "Apples", category: "Produce")
        ]

        items.forEach { context.insert($0) }
        try context.save()

        // Fetch and verify
        let descriptor = FetchDescriptor<StockItem>(sortBy: [SortDescriptor<StockItem>(\.name)])
        let fetchedItems = try context.fetch(descriptor)

        #expect(fetchedItems.count == 3)
        #expect(fetchedItems[0].name == "Apples")
        #expect(fetchedItems[1].name == "Bread")
        #expect(fetchedItems[2].name == "Milk")
    }

    @Test func stockItem_id_is_unique() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        let item1 = StockItem(name: "Item 1")
        let item2 = StockItem(name: "Item 2")

        #expect(item1.id != item2.id)

        context.insert(item1)
        context.insert(item2)
        try context.save()

        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)

        #expect(items.count == 2)
        let ids = Set(items.map { $0.id })
        #expect(ids.count == 2)
    }
}
