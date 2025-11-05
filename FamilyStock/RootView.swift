//
//  RootView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @StateObject private var auth = SupabaseClient.shared
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var syncService: SyncService?
    @State private var hasPerformedInitialSync = false

    var body: some View {
        if auth.isAuthenticated {
            TabView {
                StockListView()
                    .tabItem { Label(String(localized: "Stock"), systemImage: "shippingbox") }

                ShoppingListView()
                    .tabItem { Label(String(localized: "Shopping"), systemImage: "cart") }

                ReceiptListView()
                    .tabItem { Label(String(localized: "Receipts"), systemImage: "doc.text") }

                SettingsView()
                    .tabItem { Label(String(localized: "Settings"), systemImage: "gearshape") }
            }
            .task {
                if syncService == nil {
                    syncService = SyncService(context: context)
                }
                if auth.isAuthenticated && !hasPerformedInitialSync {
                    hasPerformedInitialSync = true
                    Task {
                        print("🔄 Performing initial sync (Tab .task)")
                        await syncService?.pullAll()
                        print("✅ Initial sync finished")
                    }
                }
            }
            .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    // Pull all data from Supabase when user signs in
                    Task {
                        // Ensure syncService is initialized
                        if syncService == nil {
                            syncService = SyncService(context: context)
                        }
                        guard !hasPerformedInitialSync else { return }
                        hasPerformedInitialSync = true
                        print("🔄 Pulling data from Supabase after login...")
                        await syncService?.pullAll()
                        print("✅ Initial data pull completed")
                    }
                } else {
                    hasPerformedInitialSync = false
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Process pending syncs when app becomes active
                    Task {
                        await syncService?.processPendingSyncs()
                    }
                }
            }
        } else {
            AuthView()
        }
    }
}
#Preview {
    RootView()
}
