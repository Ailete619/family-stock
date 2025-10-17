//
//  ShoppingListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Query(sort: \ShoppingEntry.updatedAt, order: .reverse)
    private var entries: [ShoppingEntry]

    @Query(sort: \StockItem.name)
    private var items: [StockItem]

    var body: some View {
        let nameById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.name) })

        return NavigationStack {
            List(entries.filter { !$0.isDeleted }) { entry in
                ShoppingListRow(entry: entry, itemName: nameById[entry.itemId] ?? "Unknown")
            }
            .navigationTitle(String(localized: "Shopping"))
        }
    }
}

struct ShoppingListRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var entry: ShoppingEntry
    let itemName: String

    @State private var quantityText: String = ""
    @FocusState private var isQuantityFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(itemName)
                .font(.body)
                .strikethrough(entry.isCompleted, color: .secondary)
                .foregroundStyle(entry.isCompleted ? .secondary : .primary)

            Spacer()

            TextField("Qty", text: $quantityText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                .focused($isQuantityFocused)
                .onChange(of: quantityText) { _, new in
                    updateQuantity(with: new)
                }
                .onAppear {
                    quantityText = format(entry.desiredQuantity)
                }

            Button {
                toggleCompleted()
            } label: {
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(entry.isCompleted ? .green : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(entry.isCompleted ? String(localized: "Mark as incomplete") : String(localized: "Mark as complete"))
        }
        .contentShape(Rectangle())
    }

    private func format(_ d: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: d)) ?? "0"
    }

    private func updateQuantity(with text: String) {
        guard let value = parseDouble(text) else { return }
        entry.desiredQuantity = value
        entry.updatedAt = .now
        try? context.save()
    }

    private func parseDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private func toggleCompleted() {
        entry.isCompleted.toggle()
        entry.updatedAt = .now
        try? context.save()
    }
}

#Preview {
    ShoppingListView()
}
