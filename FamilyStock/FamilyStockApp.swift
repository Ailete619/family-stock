//
//  FamilyStockApp.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

@main
struct FamilyStockApp: App {
    let container: ModelContainer = {
        do {
            // Use the default on-disk container for our models
            return try ModelContainer(
                for: StockItem.self,
                ShoppingListEntry.self,
                Receipt.self,
                ReceiptItem.self,
                PendingSync.self
            )
        } catch {
            print("❌ App: Failed to initialize persistent ModelContainer: \(error)")
            do {
                // Fallback to an in-memory container so the UI can still run
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(
                    for: StockItem.self,
                    ShoppingListEntry.self,
                    Receipt.self,
                    ReceiptItem.self,
                    PendingSync.self,
                    configurations: configuration
                )
            } catch {
                fatalError("❌ App: Unable to create even an in-memory ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
