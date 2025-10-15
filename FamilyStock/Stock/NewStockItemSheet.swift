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
        NavigationStack {
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
                        let item = Item(name: name.trimmingCharacters(in: .whitespaces),
                                        category: category.isEmpty ? nil : category)
                        context.insert(item)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
