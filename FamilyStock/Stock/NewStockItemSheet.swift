//
//  NewStockItemSheet.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct NewStockItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name: String = ""
    @State private var category: String = ""

    var body: some View {
        return NavigationStack {
            Form {
                TextField(String(localized: "Name"), text: $name)
                    .textInputAutocapitalization(.words)
                TextField(String(localized: "Category (optional)"), text: $category)
            }
            .navigationTitle(String(localized: "New Item"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        let item = StockItem(name: trimmed, category: category.isEmpty ? nil : category)
                        context.insert(item)

                        do {
                            try context.save()
                        } catch {
                            assertionFailure("Failed to save new stock item: \(error)")
                        }

                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
