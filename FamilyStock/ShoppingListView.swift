//
//  ShoppingListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI

struct ShoppingListView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Milk – 2")
                Text("Paper towels – 1")
            }
            .navigationTitle("Shopping")
        }
    }
}
#Preview {
    ShoppingListView()
}