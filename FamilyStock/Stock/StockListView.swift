//
//  StockListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct StockListView: View {
    @Query(sort: \StockItem.name) private var items: [StockItem]
    @Environment(\.modelContext) private var context
    @State private var isPresentingNew = false
    @State private var itemBeingEdited: StockItem?
    @State private var pendingDeletion: StockItem?

    var body: some View {
        let filteredItems = items.filter { !$0.isArchived }

        return NavigationStack {
            List(filteredItems) { item in
                StockListRow(
                    item: item,
                    onEdit: { itemBeingEdited = item },
                    onDelete: { pendingDeletion = item },
                    onAddToShopping: { addToShoppingList(item) }
                )
            }
            .navigationTitle(String(localized: "Stock"))   // i18n-ready
            .toolbar {
                Button {
                    isPresentingNew = true
                } label: {
                    Label(String(localized: "Add Item"), systemImage: "plus")
                }
                .accessibilityIdentifier("AddItem")
            }
            .sheet(isPresented: $isPresentingNew) {
                StockItemSheet(mode: .create)
            }
            .sheet(item: $itemBeingEdited) { item in
                StockItemSheet(mode: .edit(existing: item))
            }
            .alert(item: $pendingDeletion) { item in
                Alert(
                    title: Text(String(localized: "Delete Item")),
                    message: Text("Are you sure you want to delete \"\(item.name)\"?"),
                    primaryButton: .destructive(Text(String(localized: "Delete"))) {
                        delete(item)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

#Preview {
    StockListView()
}

private extension StockListView {
    func delete(_ item: StockItem) {
        withAnimation {
            item.isArchived = true
            item.updatedAt = .now
            pendingDeletion = nil
        }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to delete item: \(error)")
        }
    }

    func addToShoppingList(_ item: StockItem) {
        let savedID = item.id
        let predicate = #Predicate<ShoppingEntry> { entry in
            entry.itemId == savedID && entry.isDeleted == false
        }
        let descriptor = FetchDescriptor<ShoppingEntry>(predicate: predicate, sortBy: [])
        let increment = item.quantityFullStock
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.desiredQuantity += increment
            existing.updatedAt = .now
        } else {
            let entry = ShoppingEntry(
                itemId: item.id,
                desiredQuantity: increment,
                unit: ""
            )
            entry.updatedAt = .now
            context.insert(entry)
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to add item to shopping list: \(error)")
        }
    }
}
