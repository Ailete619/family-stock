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
    @StateObject private var auth = SupabaseClient.shared
    @State private var isPresentingNew = false
    @State private var itemBeingEdited: StockItem?
    @State private var pendingDeletion: StockItem?
    @State private var syncService: SyncService?

    var body: some View {
        let filteredItems = items.filter { !$0.isArchived }

        return NavigationStack {
            List(filteredItems) { item in
                StockListRow(
                    item: item,
                    onEdit: { itemBeingEdited = item },
                    onDelete: { pendingDeletion = item },
                    onAddToShopping: { addToShoppingList(item) },
                    onQuantityChange: { updateQuantity(item) }
                )
            }
            .navigationTitle(String(localized: "Stock"))   // i18n-ready
            .task {
                // Create service once when view appears
                if syncService == nil {
                    syncService = SyncService(context: context)
                }
            }
            .refreshable {
                // Pull stock items from Supabase
                await syncService?.pullItems()
            }
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
    func updateQuantity(_ item: StockItem) {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save quantity change: \(error)")
            return
        }

        // Sync to Supabase
        guard let syncService = syncService, !auth.isLocalOnly else { return }

        Task {
            await syncService.pushItem(item)
        }
    }

    func delete(_ item: StockItem) {
        withAnimation {
            item.isArchived = true
            item.updatedAt = .now
            pendingDeletion = nil
        }
        do {
            try context.save()

            // Push the archived state to Supabase
            Task {
                await syncService?.pushItem(item)
            }
        } catch {
            assertionFailure("Failed to delete item: \(error)")
        }
    }

    func addToShoppingList(_ item: StockItem) {
        let savedID = item.id
        let predicate = #Predicate<ShoppingListEntry> { entry in
            entry.itemId == savedID && entry.isDeleted == false
        }
        let descriptor = FetchDescriptor<ShoppingListEntry>(predicate: predicate, sortBy: [])
        let quantity = item.quantityFullStock > 0 ? item.quantityFullStock : 1
        if let existing = (try? context.fetch(descriptor))?.first {
            // Set the quantity to full stock instead of adding to it
            existing.desiredQuantity = quantity
            existing.updatedAt = Date.now
        } else {
            guard let userId = auth.currentUser?.id else {
                return // Can't create shopping entry without authenticated user
            }
            let entry = ShoppingListEntry(
                userId: userId,
                itemId: item.id,
                desiredQuantity: quantity,
                unit: ""
            )
            entry.updatedAt = Date.now
            context.insert(entry)
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to add item to shopping list: \(error)")
        }

        // Sync changes to Supabase
        guard let syncService = syncService, !auth.isLocalOnly else { return }

        Task {
            do {
                // Push the shopping entry changes
                if let existing = (try? context.fetch(descriptor))?.first {
                    try await syncService.pushShoppingEntry(existing)
                }
            } catch {
                print("Failed to sync shopping entry: \(error)")
            }
        }
    }
}
