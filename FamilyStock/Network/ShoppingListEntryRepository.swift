//
//  ShoppingListEntryRepository.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation

protocol ShoppingListEntryRepository {
    func fetchUpdatedSince(_ date: Date?) async throws -> [ShoppingListEntryDTO]
    func upsert(_ entry: ShoppingListEntryDTO) async throws -> ShoppingListEntryDTO
}

struct SupabaseShoppingListEntryRepository: ShoppingListEntryRepository {
    let client: HTTPClient

    init(client: HTTPClient = .init(baseURL: Secrets.shared.baseURL,
                                    anonKey: Secrets.shared.anonKey)) {
        self.client = client
    }

    func fetchUpdatedSince(_ date: Date?) async throws -> [ShoppingListEntryDTO] {
        // Get current user ID from SupabaseClient
        guard let userId = await SupabaseClient.shared.currentUser?.id else {
            throw SupabaseClient.AuthError.notAuthenticated
        }

        let since = date?.iso8601 ?? "1970-01-01T00:00:00Z"
        let query: [URLQueryItem] = [
            .init(name: "select", value: "*"),
            .init(name: "user_id", value: "eq.\(userId)"),
            .init(name: "updated_at", value: "gte.\(since)"),
            .init(name: "order", value: "updated_at.asc")
        ]
        return try await client.get("shopping_entries", query: query)
    }

    func upsert(_ entry: ShoppingListEntryDTO) async throws -> ShoppingListEntryDTO {
        let query: [URLQueryItem] = [
            .init(name: "id", value: "eq.\(entry.id)")
        ]

        // Try to fetch existing entry
        let existing: [ShoppingListEntryDTO]? = try? await client.get("shopping_entries", query: query)

        if existing?.isEmpty == false {
            // Entry exists, use PATCH
            return try await client.patch("shopping_entries", body: entry, query: query)
        } else {
            // Entry doesn't exist, use POST
            let result: [ShoppingListEntryDTO] = try await client.post("shopping_entries", body: entry)
            guard let first = result.first else {
                throw URLError(.cannotParseResponse)
            }
            return first
        }
    }
}

private extension Date {
    var iso8601: String { ISO8601DateFormatter().string(from: self) }
}
