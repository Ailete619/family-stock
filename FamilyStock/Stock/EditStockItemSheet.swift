//
//  EditStockItemSheet.swift
//  FamilyStock
//
//  Created by Codex on 2025/10/15.
//

import SwiftUI
import SwiftData

struct EditStockItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var item: StockItem

    @State private var name: String
    @State private var category: String

    init(item: StockItem) {
        self._item = Bindable(item)
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: "Name"), text: $name)
                    .textInputAutocapitalization(.words)
                TextField(String(localized: "Category (optional)"), text: $category)
            }
            .navigationTitle(String(localized: "Edit Item"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveChanges()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        item.name = trimmedName
        item.category = category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : category.trimmingCharacters(in: .whitespacesAndNewlines)
        item.updatedAt = .now

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save edits: \(error)")
        }

        dismiss()
    }
}

#Preview {
    let item = StockItem(name: "Sample Item", category: "Pantry")
    return EditStockItemSheet(item: item)
}
