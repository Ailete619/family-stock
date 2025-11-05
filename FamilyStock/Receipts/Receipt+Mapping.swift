//
//  Receipt+Mapping.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import SwiftData
import Foundation

extension Receipt {
    static func upsert(from dto: ReceiptDTO, items itemDTOs: [ReceiptItemDTO], in ctx: ModelContext) throws {
        // Normalize ID to lowercase for consistent storage
        let normalizedId = dto.id.lowercased()

        // Fetch existing receipt by normalized ID
        let predicate = #Predicate<Receipt> { receipt in
            receipt.id == normalizedId
        }
        var descriptor = FetchDescriptor<Receipt>(predicate: predicate)
        descriptor.fetchLimit = 1

        let existingReceipts = try ctx.fetch(descriptor)

        if let existing = existingReceipts.first {
            existing.userId = dto.user_id
            existing.shopName = dto.shop_name
            existing.timestamp = dto.timestamp
            existing.amount = dto.amount

            // Update receipt items with normalized IDs
            let normalizedDtoItemIds = Set(itemDTOs.map { $0.id.lowercased() })
            existing.items.removeAll { !normalizedDtoItemIds.contains($0.id.lowercased()) }

            // Upsert items
            for itemDTO in itemDTOs {
                let normalizedItemId = itemDTO.id.lowercased()
                if let existingItem = existing.items.first(where: { $0.id.lowercased() == normalizedItemId }) {
                    existingItem.itemName = itemDTO.item_name
                    existingItem.quantity = itemDTO.quantity
                } else {
                    let newItem = ReceiptItem(
                        id: normalizedItemId,
                        itemName: itemDTO.item_name,
                        quantity: itemDTO.quantity,
                        receipt: existing
                    )
                    ctx.insert(newItem)
                    existing.items.append(newItem)
                }
            }
        } else {
            // Create new receipt with normalized ID
            let receipt = Receipt(
                id: normalizedId,
                userId: dto.user_id,
                shopName: dto.shop_name,
                timestamp: dto.timestamp,
                amount: dto.amount
            )
            ctx.insert(receipt)

            // Create receipt items with normalized IDs
            for itemDTO in itemDTOs {
                let item = ReceiptItem(
                    id: itemDTO.id.lowercased(),
                    itemName: itemDTO.item_name,
                    quantity: itemDTO.quantity,
                    receipt: receipt
                )
                ctx.insert(item)
                receipt.items.append(item)
            }
        }
    }

    func toDTO() -> ReceiptDTO {
        ReceiptDTO(
            id: id,
            user_id: userId,
            shop_name: shopName,
            timestamp: timestamp,
            amount: amount
        )
    }

    func itemsToDTOs() -> [ReceiptItemDTO] {
        items.map { item in
            ReceiptItemDTO(
                id: item.id,
                receipt_id: id,
                item_name: item.itemName,
                quantity: item.quantity
            )
        }
    }
}
