//
//  ReceiptDetailView.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/17.
//

import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    let receipt: Receipt

    var body: some View {
        List {
            Section {
                HStack {
                    Text(String(localized: "Shop"))
                    Spacer()
                    Text(receipt.shopName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(String(localized: "Date"))
                    Spacer()
                    Text(receipt.timestamp, format: .dateTime.day().month().year().hour().minute())
                        .foregroundStyle(.secondary)
                }
                if let amount = receipt.amount {
                    HStack {
                        Text(String(localized: "Amount"))
                        Spacer()
                        Text(amount, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                ForEach(receipt.items) { item in
                    HStack {
                        Text(item.itemName)
                        Spacer()
                        Text("\(item.quantity, format: .number.precision(.fractionLength(0...2)))")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "Items"))
            }
        }
        .navigationTitle(String(localized: "Receipt"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview temporarily disabled due to SwiftData model changes
// #Preview {
//     let receipt = Receipt(userId: "preview-user-id", shopName: "Sample Store", timestamp: .now)
//     receipt.items = [
//         ReceiptItem(itemName: "Milk", quantity: 2, receipt: receipt),
//         ReceiptItem(itemName: "Bread", quantity: 1, receipt: receipt)
//     ]
//     NavigationStack {
//         ReceiptDetailView(receipt: receipt)
//     }
// }
