//
//  StockListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct StockListView: View {
    @State private var isPresentingNew = false
    @Query(sort: \Item.name) private var items: [Item]


    var body: some View {
        NavigationStack {
            List(items.filter { !$0.isDeleted }) { item in
                Text(item.name)
            }
            .navigationTitle("Stock")
            .toolbar {
                Button {
                    isPresentingNew = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                .accessibilityIdentifier("AddItem")
            }
            .sheet(isPresented: $isPresentingNew) {
                NewStockItemSheet()
            }
        }
    }
}
#Preview {
    StockListView()
}
