//
//  SupabaseItemRepository.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation

struct SupabaseItemRepository: ItemRepository {
    let client: HTTPClient

    init(client: HTTPClient = .init(baseURL: Secrets.shared.baseURL,
                                    anonKey: Secrets.shared.anonKey)) {
        self.client = client
    }

    func fetchUpdatedSince(_ date: Date?) async throws -> [StockItemDTO] {
        // Get current user ID from SupabaseClient
        guard let userId = await SupabaseClient.shared.currentUser?.id else {
            throw SupabaseClient.AuthError.notAuthenticated
        }

        // PostgREST filter: user_id=eq.<userId> AND updated_at=gte.<ISO8601> ; select=* ; order=updated_at.asc
        let since = date?.iso8601 ?? "1970-01-01T00:00:00Z"
        let query: [URLQueryItem] = [
            .init(name: "select", value: "*"),
            .init(name: "user_id", value: "eq.\(userId)"),
            .init(name: "updated_at", value: "gte.\(since)"),
            .init(name: "order", value: "updated_at.asc")
        ]
        return try await client.get("stock_items", query: query)
    }

    func upsert(_ item: StockItemDTO) async throws -> StockItemDTO {
        // Get current user ID to ensure RLS compliance
        guard let currentUserId = await SupabaseClient.shared.currentUser?.id else {
            throw SupabaseClient.AuthError.notAuthenticated
        }

        // Create a DTO with the current user's ID to satisfy RLS policy
        var itemToSync = item
        itemToSync.user_id = currentUserId

        // PostgREST upsert uses POST with on_conflict query parameter
        // We need to check if item exists first, then use POST or PATCH
        let query: [URLQueryItem] = [
            .init(name: "id", value: "eq.\(item.id)")
        ]

        // Try to fetch existing item
        let existing: [StockItemDTO]? = try? await client.get("stock_items", query: query)

        if let existingItem = existing?.first {
            // Item exists, check for conflict
            let resolver = ConflictResolver()
            if resolver.hasConflict(localUpdatedAt: itemToSync.updated_at, remoteUpdatedAt: existingItem.updated_at) {
                print("⚠️ Conflict detected for item \(item.id), resolving with last-write-wins")
                let resolved = resolver.resolve(local: itemToSync, remote: existingItem)
                return try await client.patch("stock_items", body: resolved, query: query)
            }
            // No conflict, proceed with update
            return try await client.patch("stock_items", body: itemToSync, query: query)
        } else {
            // Item doesn't exist, use POST with current user ID
            let result: [StockItemDTO] = try await client.post("stock_items", body: itemToSync)
            guard let first = result.first else {
                throw URLError(.cannotParseResponse)
            }
            return first
        }
    }

    func delete(id: String) async throws {
        let query: [URLQueryItem] = [
            .init(name: "id", value: "eq.\(id)")
        ]
        try await client.delete("stock_items", query: query)
    }
}

private extension Date {
    var iso8601: String { ISO8601DateFormatter().string(from: self) }
}
