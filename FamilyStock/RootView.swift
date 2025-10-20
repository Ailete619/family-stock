//
//  RootView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            StockListView()
                .tabItem { Label(String(localized: "Stock"), systemImage: "shippingbox") }

            ShoppingListView()
                .tabItem { Label(String(localized: "Shopping"), systemImage: "cart") }

            ReceiptListView()
                .tabItem { Label(String(localized: "Receipts"), systemImage: "doc.text") }
        }
    }
}
#Preview {
    RootView()
}
