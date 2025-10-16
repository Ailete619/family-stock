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

    var body: some View {
        HStack(spacing: 12) {
            Text(item.name)

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
