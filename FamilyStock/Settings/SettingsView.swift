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
                        if auth.isLocalOnly {
                            LabeledContent("Mode", value: "Local Only")
                            Text("Your data is stored only on this device")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            LabeledContent("Email", value: user.email)
                            LabeledContent("User ID", value: user.id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Account")
                }

                if auth.isLocalOnly {
                    Section {
                        Text("Sign in to sync your data across devices")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            auth.signOut()
                        } label: {
                            Label("Sign In / Sign Up", systemImage: "person.crop.circle.badge.plus")
                        }
                    } header: {
                        Text("Cloud Sync")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        auth.signOut()
                    } label: {
                        Label(auth.isLocalOnly ? "Clear Local Data" : "Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
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
