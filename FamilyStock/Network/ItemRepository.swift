//
//  ItemRepository.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation

protocol ItemRepository {
    func fetchUpdatedSince(_ date: Date?) async throws -> [StockItemDTO]
    func upsert(_ item: StockItemDTO) async throws -> StockItemDTO
    func delete(id: String) async throws
}
