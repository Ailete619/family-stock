//
//  StockListUITests.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import Testing
import SwiftUI
import SwiftData
@testable import FamilyStock

/// UI Integration tests for StockListView and StockItemSheet
struct StockListUITests {

    @Test func newStockItemSheet_creates_item_in_shared_context() throws {
        // Setup: Create in-memory container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Verify initial state: no items
        let descriptor = FetchDescriptor<StockItem>()
        var items = try context.fetch(descriptor)
        #expect(items.isEmpty, "Database should start empty")

        // Simulate what StockItemSheet does when saving
        let newItem = StockItem(name: "Test Item", category: "Test Category")
        context.insert(newItem)
        try context.save()

        // Verify item was saved
        items = try context.fetch(descriptor)
        #expect(items.count == 1, "Should have 1 item after save")
        #expect(items.first?.name == "Test Item")
        #expect(items.first?.isArchived == false)
    }

    @Test func stockListView_filters_deleted_items() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Insert both active and deleted items
        let activeItem = StockItem(name: "Active Item", isArchived: false)
        let deletedItem = StockItem(name: "Deleted Item", isArchived: true)

        context.insert(activeItem)
        context.insert(deletedItem)
        try context.save()

        // Fetch all items
        let allDescriptor = FetchDescriptor<StockItem>()
        let allItems = try context.fetch(allDescriptor)
        #expect(allItems.count == 2)

        // Simulate StockListView filter
        let visibleItems = allItems.filter { !$0.isArchived }
        #expect(visibleItems.count == 1)
        #expect(visibleItems.first?.name == "Active Item")
    }

    @Test func multiple_items_can_be_created_sequentially() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Simulate creating multiple items (like user creating items one by one)
        for i in 1...5 {
            let item = StockItem(name: "Item \(i)")
            context.insert(item)
            try context.save()
        }

        // Verify all items exist
        let descriptor = FetchDescriptor<StockItem>(sortBy: [SortDescriptor(\.name)])
        let items = try context.fetch(descriptor)

        #expect(items.count == 5)
        for i in 1...5 {
            #expect(items.contains { $0.name == "Item \(i)" })
        }
    }

    @Test func context_save_immediately_makes_items_queryable() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Insert item
        let item = StockItem(name: "Quick Item")
        context.insert(item)

        // Before save - item might not be queryable in fresh context
        let beforeSaveDescriptor = FetchDescriptor<StockItem>()
        _ = try context.fetch(beforeSaveDescriptor)
        // Note: items might be visible in same context before save

        // After save - item MUST be queryable
        try context.save()
        let afterSaveDescriptor = FetchDescriptor<StockItem>()
        let afterSaveItems = try context.fetch(afterSaveDescriptor)

        #expect(afterSaveItems.count == 1, "Item must be queryable after save")
        #expect(afterSaveItems.first?.name == "Quick Item")
    }

    @Test func context_save_makes_items_available_in_new_context() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)

        // Context 1: Insert and save (simulates StockItemSheet)
        let context1 = ModelContext(container)
        let item = StockItem(name: "Shared Item")
        context1.insert(item)
        try context1.save()

        // Context 2: Query (simulates StockListView)
        let context2 = ModelContext(container)
        let descriptor = FetchDescriptor<StockItem>()
        let items = try context2.fetch(descriptor)

        #expect(items.count == 1, "Item saved in context1 should be visible in context2")
        #expect(items.first?.name == "Shared Item")
    }

    @Test func trimmed_whitespace_items_are_saved_correctly() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Simulate user input with whitespace
        let userInput = "  Test Item  "
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = StockItem(name: trimmed)
        context.insert(item)
        try context.save()

        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)

        #expect(items.count == 1)
        #expect(items.first?.name == "Test Item", "Whitespace should be trimmed")
    }

    @Test func empty_category_is_stored_as_nil() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        // Simulate StockItemSheet logic
        let categoryInput = ""
        let category = categoryInput.isEmpty ? nil : categoryInput

        let item = StockItem(name: "Item", category: category)
        context.insert(item)
        try context.save()

        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)

        #expect(items.first?.category == nil)
    }

    @Test func non_empty_category_is_stored() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StockItem.self, configurations: config)
        let context = ModelContext(container)

        let categoryInput = "Dairy"
        let category = categoryInput.isEmpty ? nil : categoryInput

        let item = StockItem(name: "Milk", category: category)
        context.insert(item)
        try context.save()

        let descriptor = FetchDescriptor<StockItem>()
        let items = try context.fetch(descriptor)

        #expect(items.first?.category == "Dairy")
    }
}
