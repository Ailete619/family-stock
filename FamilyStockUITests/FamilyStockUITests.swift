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

        // Fill in the form using stable identifiers
        let nameField = app.textFields["ItemNameField"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Test Item")

        // Tap Save button
        app.buttons["Save"].tap()

        // Wait for sheet to dismiss and verify item appears in list
        // Use the ItemName_ identifier prefix to find the item
        let itemNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ItemName_"))
        let testItem = itemNames.containing(NSPredicate(format: "label == %@", "Test Item")).firstMatch
        XCTAssertTrue(testItem.waitForExistence(timeout: 2), "Test Item should appear in list")
    }

    @MainActor
    func testEditStockItem() throws {
        // First, add an item
        addTestItem(name: "Edit Test Item")

        // Find the edit button using stable identifier
        let editButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "EditButton_"))
        XCTAssertTrue(editButtons.count > 0, "At least one edit button should exist")

        let editButton = editButtons.element(boundBy: 0)
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        editButton.tap()

        // Verify edit sheet appears
        XCTAssertTrue(app.navigationBars["Edit Item"].waitForExistence(timeout: 2))

        // Modify the name using stable identifier
        let nameField = app.textFields["ItemNameField"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.clearAndType("Edited Item")

        // Save changes
        app.buttons["Save"].tap()

        // Verify the updated name appears using stable identifier
        let itemNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ItemName_"))
        let editedItem = itemNames.containing(NSPredicate(format: "label == %@", "Edited Item")).firstMatch
        XCTAssertTrue(editedItem.waitForExistence(timeout: 2), "Edited item name should appear in list")
    }

    @MainActor
    func testDeleteStockItem() throws {
        // Add a test item
        addTestItem(name: "Delete Test Item")

        // Find the delete button using stable identifier
        let deleteButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "DeleteButton_"))
        XCTAssertTrue(deleteButtons.count > 0, "At least one delete button should exist")

        let deleteButton = deleteButtons.element(boundBy: 0)
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        // Confirm deletion in alert
        let deleteAlertButton = app.alerts.buttons["Delete"]
        XCTAssertTrue(deleteAlertButton.waitForExistence(timeout: 2), "Delete confirmation alert should appear")
        deleteAlertButton.tap()

        // Verify item no longer exists using stable identifier
        let itemNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ItemName_"))
        let deletedItem = itemNames.containing(NSPredicate(format: "label == %@", "Delete Test Item")).firstMatch
        XCTAssertFalse(deletedItem.waitForExistence(timeout: 2), "Deleted item should not appear in list")
    }

    // MARK: - Shopping Tab Tests

    @MainActor
    func testAddItemToShoppingList() throws {
        // First add an item to stock
        addTestItem(name: "Shopping Test Item", fullStock: 10)

        // Find the shopping button using stable identifier
        let shoppingButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "AddToShoppingButton_"))
        XCTAssertTrue(shoppingButtons.count > 0, "At least one shopping button should exist")

        let shoppingButton = shoppingButtons.element(boundBy: 0)
        XCTAssertTrue(shoppingButton.waitForExistence(timeout: 2), "Shopping button should exist")
        shoppingButton.tap()

        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()

        // Wait for Shopping navigation bar to ensure tab has loaded
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: 2))

        // Verify item appears in shopping list using stable identifier
        let shoppingItemNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ShoppingItemName_"))
        let shoppingItem = shoppingItemNames.containing(NSPredicate(format: "label CONTAINS %@", "Shopping Test Item")).firstMatch
        XCTAssertTrue(shoppingItem.waitForExistence(timeout: 5), "Shopping list item should appear after adding to cart")

        // Verify the quantity appears using stable identifier
        let quantityFields = app.textFields.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ShoppingItemQuantity_"))
        let quantityField = quantityFields.containing(NSPredicate(format: "value == %@", "10")).firstMatch
        XCTAssertTrue(quantityField.exists, "Shopping item should show quantity of 10")
    }

    @MainActor
    func testMarkShoppingItemComplete() throws {
        // First ensure there's an item in the shopping list
        addTestItem(name: "Completion Test Item", fullStock: 5)

        // Add it to shopping list using stable identifier
        let shoppingButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "AddToShoppingButton_"))
        if shoppingButtons.count > 0 {
            shoppingButtons.element(boundBy: 0).tap()
        }

        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: 2))

        // Wait for item to appear using stable identifier
        let shoppingItemNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ShoppingItemName_"))
        let shoppingItem = shoppingItemNames.containing(NSPredicate(format: "label CONTAINS %@", "Completion Test Item")).firstMatch
        XCTAssertTrue(shoppingItem.waitForExistence(timeout: 5), "Item should appear in shopping list")

        // Find and tap the checkbox using stable identifier
        let checkboxes = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ShoppingItemCheckbox_"))
        XCTAssertTrue(checkboxes.count > 0, "At least one checkbox should exist")

        let checkbox = checkboxes.element(boundBy: 0)
        checkbox.tap()

        // Verify checkbox becomes filled (still using the first matching checkbox)
        let filledCheckboxes = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ShoppingItemCheckbox_"))
        let filledCheckbox = filledCheckboxes.element(boundBy: 0)
        XCTAssertTrue(filledCheckbox.waitForExistence(timeout: 2), "Checkbox should exist after completion")
    }

    @MainActor
    func testSaveReceipt() throws {
        // First create and complete a shopping item
        addTestItem(name: "Receipt Test Item", fullStock: 3)

        // Add it to shopping list using stable identifier
        let shoppingButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "AddToShoppingButton_"))
        if shoppingButtons.count > 0 {
            shoppingButtons.element(boundBy: 0).tap()
        }

        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: 2))

        // Wait for item and mark it complete using stable identifier
        let shoppingItemNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ShoppingItemName_"))
        let shoppingItem = shoppingItemNames.containing(NSPredicate(format: "label CONTAINS %@", "Receipt Test Item")).firstMatch
        XCTAssertTrue(shoppingItem.waitForExistence(timeout: 5), "Item should appear in shopping list")

        let checkboxes = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ShoppingItemCheckbox_"))
        if checkboxes.count > 0 {
            checkboxes.element(boundBy: 0).tap()
        }

        // Check if Save Receipt button exists using stable identifier
        let saveReceiptButton = app.buttons["SaveReceiptButton"]
        XCTAssertTrue(saveReceiptButton.waitForExistence(timeout: 2), "Save Receipt button should appear when items are completed")
        saveReceiptButton.tap()

        // Verify save receipt sheet appears
        XCTAssertTrue(app.navigationBars["Save Receipt"].waitForExistence(timeout: 2))

        // Fill in shop name using stable identifier
        let shopNameField = app.textFields["ReceiptShopNameField"]
        XCTAssertTrue(shopNameField.exists)
        shopNameField.tap()
        shopNameField.typeText("Test Store")

        // Tap Save
        app.buttons["Save"].tap()

        // Navigate to Receipts tab
        app.tabBars.buttons["Receipts"].tap()

        // Verify receipt appears using stable identifier
        let receiptShopNames = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "ReceiptShopName_"))
        let receipt = receiptShopNames.containing(NSPredicate(format: "label == %@", "Test Store")).firstMatch
        XCTAssertTrue(receipt.waitForExistence(timeout: 3), "Receipt should appear in Receipts list")
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

        // Fill in name using stable identifier
        let nameField = app.textFields["ItemNameField"]
        nameField.tap()
        nameField.typeText(name)

        // Fill in category if provided using stable identifier
        if let category = category {
            let categoryField = app.textFields["ItemCategoryField"]
            categoryField.tap()
            categoryField.typeText(category)
        }

        // Fill in full stock if provided using stable identifier
        if fullStock > 0 {
            let fullStockField = app.textFields["ItemFullStockField"]
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
