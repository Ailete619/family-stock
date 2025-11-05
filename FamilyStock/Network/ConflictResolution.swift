//
//  ConflictResolution.swift
//  FamilyStock
//
//  Created by Claude on 2025/11/04.
//

import Foundation

/// Conflict resolution strategy for sync conflicts
enum ConflictResolution {
    /// Last-Write-Wins based on updated_at timestamp
    case lastWriteWins

    /// Manual resolution required (not implemented yet)
    case manual
}

/// Result of a conflict check
enum ConflictCheckResult<T> {
    /// No conflict, proceed with operation
    case noConflict(T)

    /// Conflict detected, server has newer version
    case conflict(local: T, remote: T)

    /// Resolved conflict using strategy
    case resolved(T)
}

/// Helper for resolving conflicts between local and remote data
struct ConflictResolver {
    let strategy: ConflictResolution

    init(strategy: ConflictResolution = .lastWriteWins) {
        self.strategy = strategy
    }

    /// Resolve conflict between local and remote stock items
    func resolve(local: StockItemDTO, remote: StockItemDTO) -> StockItemDTO {
        switch strategy {
        case .lastWriteWins:
            return local.updated_at > remote.updated_at ? local : remote
        case .manual:
            // For now, default to last write wins
            return local.updated_at > remote.updated_at ? local : remote
        }
    }

    /// Resolve conflict between local and remote shopping entries
    func resolve(local: ShoppingListEntryDTO, remote: ShoppingListEntryDTO) -> ShoppingListEntryDTO {
        switch strategy {
        case .lastWriteWins:
            return local.updated_at > remote.updated_at ? local : remote
        case .manual:
            return local.updated_at > remote.updated_at ? local : remote
        }
    }

    /// Resolve conflict between local and remote receipts
    func resolve(local: ReceiptDTO, remote: ReceiptDTO) -> ReceiptDTO {
        switch strategy {
        case .lastWriteWins:
            // Receipts use timestamp instead of updated_at
            return local.timestamp > remote.timestamp ? local : remote
        case .manual:
            return local.timestamp > remote.timestamp ? local : remote
        }
    }

    /// Check if local update would cause a conflict
    /// Returns true if remote has newer changes that would be overwritten
    func hasConflict(localUpdatedAt: Date, remoteUpdatedAt: Date) -> Bool {
        return remoteUpdatedAt > localUpdatedAt
    }
}
