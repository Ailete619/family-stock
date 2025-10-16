//
//  StockItemSheet.swift
//  FamilyStock
//
//  Created by Codex on 2025/10/15.
//

import SwiftUI
import SwiftData

struct StockItemSheet: View {
    enum Mode {
        case create
        case edit(existing: StockItem)

        var title: String {
            switch self {
            case .create:
                return String(localized: "New Item")
            case .edit:
                return String(localized: "Edit Item")
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let mode: Mode
    @State private var name: String
    @State private var category: String

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _category = State(initialValue: "")
        case .edit(existing: let item):
            _name = State(initialValue: item.name)
            _category = State(initialValue: item.category ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: "Name"), text: $name)
                    .textInputAutocapitalization(.words)
                TextField(String(localized: "Category (optional)"), text: $category)
            }
            .navigationTitle(mode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private extension StockItemSheet {
    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryValue = trimmedCategory.isEmpty ? nil : trimmedCategory

        switch mode {
        case .create:
            let item = StockItem(name: trimmedName, category: categoryValue)
            item.updatedAt = .now
            context.insert(item)
        case .edit(existing: let item):
            item.name = trimmedName
            item.category = categoryValue
            item.updatedAt = .now
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save stock item: \(error)")
        }

        dismiss()
    }
}

#Preview("Create") {
    StockItemSheet(mode: .create)
}

#Preview("Edit") {
    let item = StockItem(name: "Sample", category: "Pantry")
    return StockItemSheet(mode: .edit(existing: item))
}
