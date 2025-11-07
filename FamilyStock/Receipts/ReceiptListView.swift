//
//  ReceiptListView.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/17.
//

import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Query(sort: \Receipt.timestamp, order: .reverse)
    private var receipts: [Receipt]

    @Environment(\.modelContext) private var context
    @State private var syncService: SyncService?

    var body: some View {
        NavigationStack {
            List(receipts) { receipt in
                NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(receipt.shopName)
                            .font(.headline)
                            .accessibilityIdentifier("ReceiptShopName_\(receipt.id)")
                        Text(receipt.timestamp, format: .dateTime.day().month().year().hour().minute())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("ReceiptTimestamp_\(receipt.id)")
                    }
                }
                .accessibilityIdentifier("ReceiptRow_\(receipt.id)")
            }
            .navigationTitle(String(localized: "Receipts"))
            .task {
                if syncService == nil {
                    syncService = SyncService(context: context)
                }
            }
            .refreshable {
                await syncService?.pullReceipts()
            }
        }
    }
}

#Preview {
    ReceiptListView()
}
