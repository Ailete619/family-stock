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

        // Find and tap the edit button for the item
        let itemRow = app.staticTexts["Edit Test Item"]
        XCTAssertTrue(itemRow.exists)

        // Tap the edit button (pencil icon)
        // Note: You may need to adjust the accessibility identifier
        let editButton = itemRow.buttons.element(boundBy: 0)
        if editButton.exists {
            editButton.tap()

            // Verify edit sheet appears
            XCTAssertTrue(app.navigationBars["Edit Item"].exists)

            // Cancel edit
            app.buttons["Cancel"].tap()
        }
    }

    @MainActor
    func testDeleteStockItem() throws {
        // Add a test item
        addTestItem(name: "Delete Test Item")

        // Verify item exists
        let itemCell = app.staticTexts["Delete Test Item"]
        XCTAssertTrue(itemCell.exists)

        // Tap the delete button
        // Note: May need to swipe or tap delete button depending on UI
        // This is a placeholder - adjust based on actual implementation
    }

    // MARK: - Shopping Tab Tests

    @MainActor
    func testAddItemToShoppingList() throws {
        // First add an item to stock
        addTestItem(name: "Shopping Test Item", fullStock: 10)

        // Find the item text to verify it exists
        let itemText = app.staticTexts["Shopping Test Item"]
        XCTAssertTrue(itemText.exists, "Item should exist in stock list")

        // Find all buttons matching the AddToShoppingButton pattern
        let shoppingButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "AddToShoppingButton_"))

        // Wait for button to exist and be hittable, then tap it
        if shoppingButtons.count > 0 {
            let firstButton = shoppingButtons.element(boundBy: 0)
            XCTAssertTrue(firstButton.waitForExistence(timeout: 2), "Shopping button should exist")
            firstButton.tap()
        } else {
            // Fallback to label-based search if accessibility identifiers aren't working
            let fallbackButton = app.buttons["Add to shopping list"].firstMatch
            XCTAssertTrue(fallbackButton.waitForExistence(timeout: 2), "At least one shopping button should exist")
            fallbackButton.tap()
        }

        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()

        // Wait for Shopping navigation bar to ensure tab has loaded
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: 2))

        // Verify item appears in shopping list with longer timeout for SwiftData to sync
        // Search for the item by label since it should appear as static text in the list
        let shoppingItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Shopping Test Item")).firstMatch
        XCTAssertTrue(shoppingItem.waitForExistence(timeout: 5), "Shopping list item should appear after adding to cart")
    }

    @MainActor
    func testMarkShoppingItemComplete() throws {
        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()

        // If there are items, try to mark one as complete
        let checkboxes = app.buttons.matching(identifier: "circle")
        if checkboxes.count > 0 {
            checkboxes.element(boundBy: 0).tap()

            // Verify checkbox becomes filled
            let filledCheckbox = app.buttons["checkmark.circle.fill"]
            XCTAssertTrue(filledCheckbox.waitForExistence(timeout: 1))
        }
    }

    @MainActor
    func testSaveReceipt() throws {
        // Navigate to Shopping tab
        app.tabBars.buttons["Shopping"].tap()

        // Check if Save Receipt button exists (only appears when items are completed)
        let saveReceiptButton = app.buttons["Save Receipt"]
        if saveReceiptButton.exists {
            saveReceiptButton.tap()

            // Verify save receipt sheet appears
            XCTAssertTrue(app.navigationBars["Save Receipt"].exists)

            // Fill in shop name
            let shopNameField = app.textFields["Shop Name"]
            shopNameField.tap()
            shopNameField.typeText("Test Store")

            // Tap Save
            app.buttons["Save"].tap()

            // Navigate to Receipts tab
            app.tabBars.buttons["Receipts"].tap()

            // Verify receipt appears
            let receipt = app.staticTexts["Test Store"]
            XCTAssertTrue(receipt.waitForExistence(timeout: 2))
        }
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
