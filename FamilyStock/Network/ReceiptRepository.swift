//
//  ReceiptRepository.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation

protocol ReceiptRepository {
    func fetchUpdatedSince(_ date: Date?) async throws -> ([ReceiptDTO], [ReceiptItemDTO])
    func upsert(_ receipt: ReceiptDTO, items: [ReceiptItemDTO]) async throws -> ReceiptDTO
    func delete(id: String) async throws
}

struct SupabaseReceiptRepository: ReceiptRepository {
    let client: HTTPClient

    init(client: HTTPClient = .init(baseURL: Secrets.shared.baseURL,
                                    anonKey: Secrets.shared.anonKey)) {
        self.client = client
    }

    func fetchUpdatedSince(_ date: Date?) async throws -> ([ReceiptDTO], [ReceiptItemDTO]) {
        // Get current user ID from SupabaseClient
        guard let userId = await SupabaseClient.shared.currentUser?.id else {
            throw SupabaseClient.AuthError.notAuthenticated
        }

        let since = date?.iso8601 ?? "1970-01-01T00:00:00Z"

        // Fetch receipts
        let receiptQuery: [URLQueryItem] = [
            .init(name: "select", value: "*"),
            .init(name: "user_id", value: "eq.\(userId)"),
            .init(name: "timestamp", value: "gte.\(since)"),
            .init(name: "order", value: "timestamp.asc")
        ]
        let receipts: [ReceiptDTO] = try await client.get("receipts", query: receiptQuery)

        // Fetch all receipt items (we'll filter by receipt IDs we got)
        let itemQuery: [URLQueryItem] = [
            .init(name: "select", value: "*")
        ]
        let allItems: [ReceiptItemDTO] = try await client.get("receipt_items", query: itemQuery)

        // Filter items to only those belonging to fetched receipts
        let receiptIds = Set(receipts.map { $0.id })
        let items = allItems.filter { receiptIds.contains($0.receipt_id) }

        return (receipts, items)
    }

    func upsert(_ receipt: ReceiptDTO, items: [ReceiptItemDTO]) async throws -> ReceiptDTO {
        // Get current user ID to ensure RLS compliance
        guard let currentUserId = await SupabaseClient.shared.currentUser?.id else {
            throw SupabaseClient.AuthError.notAuthenticated
        }

        // Create a DTO with the current user's ID to satisfy RLS policy
        var receiptToSync = receipt
        receiptToSync.user_id = currentUserId

        let receiptQuery: [URLQueryItem] = [
            .init(name: "id", value: "eq.\(receipt.id)")
        ]

        // Check if receipt exists
        let existingReceipts: [ReceiptDTO]? = try? await client.get("receipts", query: receiptQuery)

        let savedReceipt: ReceiptDTO
        if let existingReceipt = existingReceipts?.first {
            // Receipt exists, check for conflict
            let resolver = ConflictResolver()
            if resolver.hasConflict(localUpdatedAt: receiptToSync.timestamp, remoteUpdatedAt: existingReceipt.timestamp) {
                print("⚠️ Conflict detected for receipt \(receipt.id), resolving with last-write-wins")
                let resolved = resolver.resolve(local: receiptToSync, remote: existingReceipt)
                savedReceipt = try await client.patch("receipts", body: resolved, query: receiptQuery)
            } else {
                // No conflict, proceed with update
                savedReceipt = try await client.patch("receipts", body: receiptToSync, query: receiptQuery)
            }
        } else {
            // Receipt doesn't exist, use POST
            let result: [ReceiptDTO] = try await client.post("receipts", body: receiptToSync)
            guard let first = result.first else {
                throw URLError(.cannotParseResponse)
            }
            savedReceipt = first
        }

        // Now upsert each receipt item
        for item in items {
            let itemQuery: [URLQueryItem] = [
                .init(name: "id", value: "eq.\(item.id)")
            ]
            let existingItems: [ReceiptItemDTO]? = try? await client.get("receipt_items", query: itemQuery)

            if existingItems?.isEmpty == false {
                let _: ReceiptItemDTO = try await client.patch("receipt_items", body: item, query: itemQuery)
            } else {
                let _: [ReceiptItemDTO] = try await client.post("receipt_items", body: item)
            }
        }

        return savedReceipt
    }

    func delete(id: String) async throws {
        // First delete all associated receipt items
        let itemQuery: [URLQueryItem] = [
            .init(name: "receipt_id", value: "eq.\(id)")
        ]
        try await client.delete("receipt_items", query: itemQuery)

        // Then delete the receipt itself
        let receiptQuery: [URLQueryItem] = [
            .init(name: "id", value: "eq.\(id)")
        ]
        try await client.delete("receipts", query: receiptQuery)
    }
}

private extension Date {
    var iso8601: String { ISO8601DateFormatter().string(from: self) }
}
