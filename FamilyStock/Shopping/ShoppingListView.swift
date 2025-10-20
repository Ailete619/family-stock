//
//  ShoppingListView.swift
//  FamilyStock
//
//  Created by Loic Henri LE TEXIER on 2025/10/15.
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Query(
        filter: #Predicate<ShoppingEntry> { entry in
            entry.isDeleted == false
        },
        sort: \ShoppingEntry.updatedAt,
        order: .reverse
    )
    private var entries: [ShoppingEntry]

    @Query(sort: \StockItem.name)
    private var items: [StockItem]

    @Environment(\.modelContext) private var context
    @State private var showingSaveSheet = false
    @State private var shopName = ""
    @State private var receiptDate = Date.now
    @State private var amountText = ""

    var body: some View {
        let nameById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.name) })
        let completedEntries = entries.filter { $0.isCompleted }

        return NavigationStack {
            List(entries) { entry in
                ShoppingListRow(entry: entry, itemName: nameById[entry.itemId] ?? "Unknown")
            }
            .navigationTitle(String(localized: "Shopping"))
            .toolbar {
                if !completedEntries.isEmpty {
                    Button {
                        showingSaveSheet = true
                    } label: {
                        Label(String(localized: "Save Receipt"), systemImage: "archivebox")
                    }
                }
            }
            .sheet(isPresented: $showingSaveSheet) {
                NavigationStack {
                    Form {
                        Section {
                            TextField(String(localized: "Shop Name"), text: $shopName)
                                .textInputAutocapitalization(.words)

                            DatePicker(
                                String(localized: "Date & Time"),
                                selection: $receiptDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )

                            TextField(String(localized: "Amount (optional)"), text: $amountText)
                                .keyboardType(.decimalPad)
                        } header: {
                            Text(String(localized: "Receipt Details"))
                        }

                        Section {
                            ForEach(completedEntries) { entry in
                                HStack {
                                    Text(nameById[entry.itemId] ?? "Unknown")
                                    Spacer()
                                    Text("\(entry.desiredQuantity, format: .number.precision(.fractionLength(0...2)))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text(String(localized: "Items"))
                        }
                    }
                    .navigationTitle(String(localized: "Save Receipt"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "Cancel")) {
                                showingSaveSheet = false
                                shopName = ""
                                receiptDate = .now
                                amountText = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "Save")) {
                                saveReceipt(completedEntries: completedEntries, nameById: nameById)
                            }
                            .disabled(shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func saveReceipt(completedEntries: [ShoppingEntry], nameById: [String: String]) {
        let trimmedShopName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedShopName.isEmpty else { return }

        // Parse amount
        let trimmedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAmount = trimmedAmount.isEmpty ? nil : Double(trimmedAmount.replacingOccurrences(of: ",", with: "."))

        // Create receipt
        let receipt = Receipt(shopName: trimmedShopName, timestamp: receiptDate, amount: parsedAmount)
        context.insert(receipt)

        // Create receipt items
        for entry in completedEntries {
            let receiptItem = ReceiptItem(
                itemName: nameById[entry.itemId] ?? "Unknown",
                quantity: entry.desiredQuantity,
                receipt: receipt
            )
            context.insert(receiptItem)
            receipt.items.append(receiptItem)

            // Mark shopping entry as deleted
            entry.isDeleted = true
        }

        do {
            try context.save()
            showingSaveSheet = false
            shopName = ""
            receiptDate = .now
            amountText = ""
        } catch {
            assertionFailure("Failed to save receipt: \(error)")
        }
    }
}

struct ShoppingListRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var entry: ShoppingEntry
    let itemName: String

    @State private var quantityText: String = ""
    @FocusState private var isQuantityFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(itemName)
                .font(.body)
                .strikethrough(entry.isCompleted, color: .secondary)
                .foregroundStyle(entry.isCompleted ? .secondary : .primary)
                .accessibilityIdentifier("ShoppingItem_\(sanitized(itemName))")

            Spacer()

            TextField("Qty", text: $quantityText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                .focused($isQuantityFocused)
                .onChange(of: quantityText) { _, new in
                    updateQuantity(with: new)
                }
                .onAppear {
                    quantityText = format(entry.desiredQuantity)
                }

            Button {
                toggleCompleted()
            } label: {
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(entry.isCompleted ? .green : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(entry.isCompleted ? String(localized: "Mark as incomplete") : String(localized: "Mark as complete"))
        }
        .contentShape(Rectangle())
    }

    private func format(_ d: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: d)) ?? "0"
    }

    private func updateQuantity(with text: String) {
        guard let value = parseDouble(text) else { return }
        entry.desiredQuantity = value
        entry.updatedAt = .now
        try? context.save()
    }

    private func parseDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private func toggleCompleted() {
        entry.isCompleted.toggle()
        entry.updatedAt = .now
        try? context.save()
    }

    private func sanitized(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}

#Preview {
    ShoppingListView()
}
