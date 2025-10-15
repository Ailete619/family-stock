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
                .tabItem { Label("Stock", systemImage: "shippingbox") }

            ShoppingListView()
                .tabItem { Label("Shopping", systemImage: "cart") }
        }
    }
}
#Preview {
    RootView()
}
