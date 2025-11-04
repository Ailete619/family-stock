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
        // Fetch existing receipt by ID using a predicate
        let predicate = #Predicate<Receipt> { receipt in
            receipt.id == dto.id
        }
        var descriptor = FetchDescriptor<Receipt>(predicate: predicate)
        descriptor.fetchLimit = 1

        let existingReceipts = try ctx.fetch(descriptor)

        if let existing = existingReceipts.first {
            existing.userId = dto.user_id
            existing.shopName = dto.shop_name
            existing.timestamp = dto.timestamp
            existing.amount = dto.amount

            // Update receipt items
            // Remove items that are no longer in the DTO list
            let dtoItemIds = Set(itemDTOs.map { $0.id })
            existing.items.removeAll { !dtoItemIds.contains($0.id) }

            // Upsert items
            for itemDTO in itemDTOs {
                if let existingItem = existing.items.first(where: { $0.id == itemDTO.id }) {
                    existingItem.itemName = itemDTO.item_name
                    existingItem.quantity = itemDTO.quantity
                } else {
                    let newItem = ReceiptItem(
                        id: itemDTO.id,
                        itemName: itemDTO.item_name,
                        quantity: itemDTO.quantity,
                        receipt: existing
                    )
                    ctx.insert(newItem)
                    existing.items.append(newItem)
                }
            }
        } else {
            // Create new receipt
            let receipt = Receipt(
                id: dto.id,
                userId: dto.user_id,
                shopName: dto.shop_name,
                timestamp: dto.timestamp,
                amount: dto.amount
            )
            ctx.insert(receipt)

            // Create receipt items
            for itemDTO in itemDTOs {
                let item = ReceiptItem(
                    id: itemDTO.id,
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
