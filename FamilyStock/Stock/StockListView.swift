//
//  StockListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct StockListView: View {
    @Query(sort: \StockItem.name) private var items: [StockItem]
    @Environment(\.modelContext) private var context
    @State private var isPresentingNew = false

    var body: some View {
        NavigationStack {
            List(items.filter { !$0.isDeleted }) { item in
                Text(item.name)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            let e = ShoppingEntry(itemId: item.id, desiredQuantity: 1, unit: "pcs")
                            context.insert(e)
                            try? context.save()
                        } label: {
                            Label(String(localized: "Add to Shopping"), systemImage: "cart.badge.plus")
                        }
                        .tint(.blue)
                    }
            }
            .navigationTitle(String(localized: "Stock"))   // i18n-ready
            .toolbar {
                Button {
                    isPresentingNew = true
                } label: {
                    Label(String(localized: "Add Item"), systemImage: "plus")
                }
                .accessibilityIdentifier("AddItem")
            }
            .sheet(isPresented: $isPresentingNew) {
                NewStockItemSheet()    // next step
            }
        }
    }
}

#Preview {
    StockListView()
}
