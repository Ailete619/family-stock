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
    @StateObject private var auth = SupabaseClient.shared
    @State private var syncService: SyncService?

    private let mode: Mode
    @State private var name: String
    @State private var category: String
    @State private var quantityInStockText: String
    @State private var fullStockText: String

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _category = State(initialValue: "")
            _quantityInStockText = State(initialValue: Self.format(0))
            _fullStockText = State(initialValue: Self.format(0))
        case .edit(existing: let item):
            _name = State(initialValue: item.name)
            _category = State(initialValue: item.category ?? "")
            _quantityInStockText = State(initialValue: Self.format(item.quantityInStock))
            _fullStockText = State(initialValue: Self.format(item.quantityFullStock))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent {
                        TextField(String(localized: "Name"), text: $name)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    } label: {
                        Text(String(localized: "Name"))
                    }

                    LabeledContent {
                        TextField(String(localized: "Category (optional)"), text: $category)
                            .multilineTextAlignment(.trailing)
                    } label: {
                        Text(String(localized: "Category"))
                    }
                }

                Section {
                    LabeledContent {
                        TextField(String(localized: "Quantity"), text: $quantityInStockText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    } label: {
                        Text(String(localized: "Quantity In Stock"))
                    }

                    LabeledContent {
                        TextField(String(localized: "Full Stock"), text: $fullStockText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Full Stock Count")
                    } label: {
                        Text(String(localized: "Full Stock Count"))
                    }
                }
            }
            .navigationTitle(mode.title)
            .task {
                if syncService == nil {
                    syncService = SyncService(context: context)
                }
            }
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

        let cleanedQuantityInStock = quantityInStockText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedQuantityInStock = Double(cleanedQuantityInStock.replacingOccurrences(of: ",", with: ".")) ?? 0

        let cleanedFullStock = fullStockText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedFullStock = Double(cleanedFullStock.replacingOccurrences(of: ",", with: ".")) ?? 0

        let savedItem: StockItem
        switch mode {
        case .create:
            guard let userId = auth.currentUser?.id else {
                return // Can't create item without authenticated user
            }
            let item = StockItem(
                userId: userId,
                name: trimmedName,
                category: categoryValue,
                quantityInStock: parsedQuantityInStock,
                quantityFullStock: parsedFullStock
            )
            item.updatedAt = Date.now
            context.insert(item)
            savedItem = item
        case .edit(existing: let item):
            item.name = trimmedName
            item.category = categoryValue
            item.quantityInStock = parsedQuantityInStock
            item.quantityFullStock = parsedFullStock
            item.updatedAt = Date.now
            savedItem = item
        }

        do {
            try context.save()

            // Push to Supabase after successful local save
            Task {
                await syncService?.pushItem(savedItem)
            }
        } catch {
            assertionFailure("Failed to save stock item: \(error)")
        }

        dismiss()
    }

    static func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}

#Preview("Create") {
    StockItemSheet(mode: .create)
}

#Preview("Edit") {
    let item = StockItem(userId: "preview-user-id", name: "Sample", category: "Pantry")
    StockItemSheet(mode: .edit(existing: item))
}
