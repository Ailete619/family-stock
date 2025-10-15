//
//  StockListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI

struct StockListView: View {
    @State private var isPresentingNew = false

    var body: some View {
        NavigationStack {
            List {
                Text("Rice")
                Text("Toothpaste")
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
                Text("New Item Sheet (stub)")
                    .padding()
            }
        }
    }
}
#Preview {
    StockListView()
}
