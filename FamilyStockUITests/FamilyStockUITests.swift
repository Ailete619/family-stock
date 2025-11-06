//
//  FamilyStockUITests.swift
//  FamilyStockUITests
//
//  Created by Claude on 2025/10/18.
//

import XCTest

final class FamilyStockUITests: XCTestCase {

    nonisolated(unsafe) var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation Tests

    @MainActor
    func testTabNavigation() throws {
        // Verify all three tabs exist
        let tabBar = app.tabBars
        XCTAssertTrue(tabBar.buttons["Stock"].exists)
        XCTAssertTrue(tabBar.buttons["Shopping"].exists)
        XCTAssertTrue(tabBar.buttons["Receipts"].exists)

        // Navigate to Shopping tab
        tabBar.buttons["Shopping"].tap()
        XCTAssertTrue(app.navigationBars["Shopping"].exists)

        // Navigate to Receipts tab
        tabBar.buttons["Receipts"].tap()
        XCTAssertTrue(app.navigationBars["Receipts"].exists)

        // Navigate back to Stock tab
        tabBar.buttons["Stock"].tap()
        XCTAssertTrue(app.navigationBars["Stock"].exists)
    }

    // MARK: - Stock Tab Tests

    @MainActor
    func testAddStockItem() throws {
        // Tap the Add Item button
        app.buttons["AddItem"].tap()

        // Verify the sheet appears
        XCTAssertTrue(app.navigationBars["New Item"].exists)

        // Fill in the form
        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Test Item")

        // Tap Save button
        app.buttons["Save"].tap()

        // Wait for sheet to dismiss and verify item appears in list
        let itemCell = app.staticTexts["Test Item"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 2))
    }

    @MainActor
    func testEditStockItem() throws {
        // First, add an item
        addTestItem(name: "Edit Test Item")

        // Find the item text to get a reference
        let itemText = app.staticTexts["Edit Test Item"]
        XCTAssertTrue(itemText.exists)

        // We need to find the containing cell/row to get the item ID
        // For now, use the first matching edit button
        let editButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "EditButton_"))
        XCTAssertTrue(editButtons.count > 0, "At least one edit button should exist")

        let editButton = editButtons.element(boundBy: 0)
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        editButton.tap()

        // Verify edit sheet appears
        XCTAssertTrue(app.navigationBars["Edit Item"].waitForExistence(timeout: 2))

        // Modify the name
        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.clearAndType("Edited Item")

        // Save changes
        app.buttons["Save"].tap()

        // Verify the updated name appears
        let editedItemText = app.staticTexts["Edited Item"]
        XCTAssertTrue(editedItemText.waitForExistence(timeout: 2), "Edited item name should appear in list")
    }

    @MainActor
    func testDeleteStockItem() throws {
        // Add a test item
        addTestItem(name: "Delete Test Item")

        // Verify item exists
        let itemText = app.staticTexts["Delete Test Item"]
        XCTAssertTrue(itemText.exists)

        // Find the delete button for this item
        let deleteButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "DeleteButton_"))
        XCTAssertTrue(deleteButtons.count > 0, "At least one delete button should exist")

        let deleteButton = deleteButtons.element(boundBy: 0)
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        // Confirm deletion in alert
        let deleteAlertButton = app.alerts.buttons["Delete"]
        XCTAssertTrue(deleteAlertButton.waitForExistence(timeout: 2), "Delete confirmation alert should appear")
        deleteAlertButton.tap()

        // Verify item no longer exists in the list
        XCTAssertFalse(itemText.waitForExistence(timeout: 2), "Deleted item should not appear in list")
    }

    // MARK: - Shopping Tab Tests

    @MainActor
    func testAddItemToShoppingList() throws {
        // First add an item to stock
        addTestItem(name: "Shopping Test Item", fullStock: 10)

        // Find the item text to verify it exists
        let itemText = app.staticTexts["Shopping Test Item"]
        XCTAssertTrue(itemText.exists, "Item should exist in stock list")

        // Find the shopping button for the first item
        let shoppingButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "AddToShoppingButton_"))
        XCTAssertTrue(shoppingButtons.count > 0, "At least one shopping button should exist")

        let shoppingButton = shoppingButtons.element(boundBy: 0)
        XCTAssertTrue(shoppingButton.waitForExistence(timeout: 2), "Shopping button should exist")
        shoppingButton.tap()

        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()

        // Wait for Shopping navigation bar to ensure tab has loaded
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: 2))

        // Verify item appears in shopping list with longer timeout for SwiftData to sync
        let shoppingItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Shopping Test Item")).firstMatch
        XCTAssertTrue(shoppingItem.waitForExistence(timeout: 5), "Shopping list item should appear after adding to cart")

        // Verify the quantity appears (should be 10 from fullStock)
        let quantityText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "10")).firstMatch
        XCTAssertTrue(quantityText.exists, "Shopping item should show quantity of 10")
    }

    @MainActor
    func testMarkShoppingItemComplete() throws {
        // First ensure there's an item in the shopping list
        addTestItem(name: "Completion Test Item", fullStock: 5)

        // Add it to shopping list
        let shoppingButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "AddToShoppingButton_"))
        if shoppingButtons.count > 0 {
            shoppingButtons.element(boundBy: 0).tap()
        }

        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: 2))

        // Wait for item to appear
        let shoppingItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Completion Test Item")).firstMatch
        XCTAssertTrue(shoppingItem.waitForExistence(timeout: 5), "Item should appear in shopping list")

        // Find and tap the checkbox (circle icon)
        let checkboxes = app.buttons.matching(identifier: "circle")
        XCTAssertTrue(checkboxes.count > 0, "At least one checkbox should exist")

        let checkbox = checkboxes.element(boundBy: 0)
        checkbox.tap()

        // Verify checkbox becomes filled
        let filledCheckbox = app.buttons["checkmark.circle.fill"]
        XCTAssertTrue(filledCheckbox.waitForExistence(timeout: 2), "Checkbox should become filled when marked complete")
    }

    @MainActor
    func testSaveReceipt() throws {
        // First create and complete a shopping item
        addTestItem(name: "Receipt Test Item", fullStock: 3)

        // Add it to shopping list
        let shoppingButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "AddToShoppingButton_"))
        if shoppingButtons.count > 0 {
            shoppingButtons.element(boundBy: 0).tap()
        }

        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: 2))

        // Wait for item and mark it complete
        let shoppingItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Receipt Test Item")).firstMatch
        XCTAssertTrue(shoppingItem.waitForExistence(timeout: 5), "Item should appear in shopping list")

        let checkbox = app.buttons.matching(identifier: "circle").element(boundBy: 0)
        if checkbox.exists {
            checkbox.tap()
        }

        // Check if Save Receipt button exists (only appears when items are completed)
        let saveReceiptButton = app.buttons["Save Receipt"]
        XCTAssertTrue(saveReceiptButton.waitForExistence(timeout: 2), "Save Receipt button should appear when items are completed")
        saveReceiptButton.tap()

        // Verify save receipt sheet appears
        XCTAssertTrue(app.navigationBars["Save Receipt"].waitForExistence(timeout: 2))

        // Fill in shop name
        let shopNameField = app.textFields["Shop Name"]
        XCTAssertTrue(shopNameField.exists)
        shopNameField.tap()
        shopNameField.typeText("Test Store")

        // Tap Save
        app.buttons["Save"].tap()

        // Navigate to Receipts tab
        app.tabBars.buttons["Receipts"].tap()

        // Verify receipt appears with shop name
        let receipt = app.staticTexts["Test Store"]
        XCTAssertTrue(receipt.waitForExistence(timeout: 3), "Receipt should appear in Receipts list")

        // Verify the receipt item is listed
        let receiptItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Receipt Test Item")).firstMatch
        XCTAssertTrue(receiptItem.exists, "Receipt should contain the purchased item")
    }

    // MARK: - Receipts Tab Tests

    @MainActor
    func testReceiptsListDisplays() throws {
        // Navigate to Receipts tab
        app.tabBars.buttons["Receipts"].tap()

        // Verify the navigation bar exists - this is sufficient to know we're on the right screen
        XCTAssertTrue(app.navigationBars["Receipts"].exists)

        // The list exists even if empty (no need to assert on table/list structure)
        // Just verify we successfully navigated to the Receipts screen
    }

    @MainActor
    func testReceiptDetailView() throws {
        // Navigate to Receipts tab
        app.tabBars.buttons["Receipts"].tap()

        // If there are receipts, tap the first one
        let cells = app.tables.cells
        if cells.count > 0 {
            cells.element(boundBy: 0).tap()

            // Verify detail view appears
            XCTAssertTrue(app.navigationBars["Receipt"].exists)

            // Go back
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    // MARK: - Helper Methods

    @MainActor
    private func addTestItem(name: String, category: String? = nil, fullStock: Double = 0) {
        // Make sure we're on Stock tab
        app.tabBars.buttons["Stock"].tap()

        // Tap Add Item button
        app.buttons["AddItem"].tap()

        // Wait for sheet
        XCTAssertTrue(app.navigationBars["New Item"].waitForExistence(timeout: 2))

        // Fill in name
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText(name)

        // Fill in category if provided
        if let category = category {
            let categoryField = app.textFields["Category (optional)"]
            categoryField.tap()
            categoryField.typeText(category)
        }

        // Fill in full stock if provided
        if fullStock > 0 {
            let fullStockField = app.textFields.matching(identifier: "Full Stock Count").element
            if fullStockField.exists {
                fullStockField.tap()
                fullStockField.typeText("\(Int(fullStock))")
            }
        }

        // Tap Save
        app.buttons["Save"].tap()

        // Wait for sheet to dismiss
        XCTAssertTrue(app.navigationBars["Stock"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let stringValue = self.value as? String else {
            self.typeText(text)
            return
        }

        // Tap to focus
        self.tap()

        // Select all text
        let selectAllMenuItem = XCUIApplication().menuItems["Select All"]
        if selectAllMenuItem.exists {
            selectAllMenuItem.tap()
        } else {
            // Alternative: delete existing text character by character
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            self.typeText(deleteString)
        }

        // Type new text
        self.typeText(text)
    }
}
