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
        // PostgREST upsert uses POST with on_conflict query parameter
        // We need to check if item exists first, then use POST or PATCH
        let query: [URLQueryItem] = [
            .init(name: "id", value: "eq.\(item.id)")
        ]

        // Try to fetch existing item
        let existing: [StockItemDTO]? = try? await client.get("stock_items", query: query)

        if existing?.isEmpty == false {
            // Item exists, use PATCH
            return try await client.patch("stock_items", body: item, query: query)
        } else {
            // Item doesn't exist, use POST
            let result: [StockItemDTO] = try await client.post("stock_items", body: item)
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
