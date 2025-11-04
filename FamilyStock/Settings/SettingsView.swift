//
//  SettingsView.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var auth = SupabaseClient.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let user = auth.currentUser {
                        LabeledContent("Email", value: user.email)
                        LabeledContent("User ID", value: user.id)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Account")
                }

                Section {
                    Button(role: .destructive) {
                        auth.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
