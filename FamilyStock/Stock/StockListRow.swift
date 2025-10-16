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

    @FocusState private var isQtyFocused: Bool
    @State private var qtyText: String = ""
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

            TextField(String(localized: "Qty"),
                      text: $qtyText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 76)
                .textFieldStyle(.roundedBorder)
                .focused($isQtyFocused)
                .onChange(of: qtyText) { _, new in
                    // parse-as-you-type; keep it forgiving
                    if let v = Double(new.replacingOccurrences(of: ",", with: ".")) {
                        item.quantityOnHand = v
                        item.updatedAt = .now
                        try? context.save()
                    }
                }
                .onAppear {
                    qtyText = format(item.quantityOnHand)
                }

            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Edit"))

                Button {
                    onAddToShopping()
                } label: {
                    Image(systemName: "cart.badge.plus")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Add to shopping list"))

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Delete"))
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
}
