//
//  ShoppingListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI

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
                HStack {
                    Text(nameById[entry.itemId] ?? "Unknown")
                    Spacer()
                    Text("\(entry.desiredQuantity, format: .number.precision(.fractionLength(0...2))) \(entry.unit)")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "Shopping"))
        }
    }
}

#Preview {
    ShoppingListView()
}
