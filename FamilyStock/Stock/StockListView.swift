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
        let filteredItems = items.filter { !$0.isDeleted }

        return NavigationStack {
            List(filteredItems) { item in
                StockListRow(item: item)
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
            .sheet(isPresented: $isPresentingNew, onDismiss: {
                let descriptor = FetchDescriptor<StockItem>()
                if let allItems = try? context.fetch(descriptor) {
                }
            }) {
                NewStockItemSheet()
            }
        }
    }
}

#Preview {
    StockListView()
}
