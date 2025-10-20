//
//  StockListRow.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct StockListRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: StockItem

    var onEdit: () -> Void
    var onDelete: () -> Void
    var onAddToShopping: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                if let category = item.category, !category.isEmpty {
                    Text(category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // Edit button
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Edit"))
                .accessibilityIdentifier("EditButton_\(item.id)")

                // Minus button to decrease quantity
                Button {
                    decreaseQuantity()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Decrease quantity"))
                .accessibilityIdentifier("DecreaseButton_\(item.id)")

                // Display quantity as "quantityInStock / quantityFullStock"
                Text("\(format(item.quantityInStock)) / \(format(item.quantityFullStock))")
                    .font(.body)
                    .monospacedDigit()
                    .frame(minWidth: 60)
                    .accessibilityIdentifier("QuantityText_\(item.id)")
            }

            HStack(spacing: 8) {
                Button {
                    onAddToShopping()
                } label: {
                    Image(systemName: "cart.badge.plus")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Add to shopping list"))
                .accessibilityIdentifier("AddToShoppingButton_\(item.id)")

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Delete"))
                .accessibilityIdentifier("DeleteButton_\(item.id)")
            }
        }
        .contentShape(Rectangle()) // keeps row tap area sane
        .accessibilityIdentifier("ItemRow_\(item.id)")
    }

    private func format(_ d: Double) -> String {
        // simple, locale-aware formatting
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: d)) ?? "0"
    }

    private func decreaseQuantity() {
        // Store the previous quantity to check if we hit zero
        let previousQuantity = item.quantityInStock

        // Decrease quantity by 1, but don't go below 0
        item.quantityInStock = max(0, item.quantityInStock - 1)
        item.updatedAt = .now
        try? context.save()

        // If we just hit zero, automatically add to shopping list
        if previousQuantity > 0 && item.quantityInStock == 0 {
            onAddToShopping()
        }
    }
}
