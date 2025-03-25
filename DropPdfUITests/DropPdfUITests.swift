import XCTest

final class DropPdfUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

//    @MainActor
//    func testShowAndCloseProcessedFilesPanel() throws {
//        let app = XCUIApplication()
//        app.launch()
//
//        // 1️⃣ Click the info button to show the sheet
//        let infoButton = app.buttons["infoButton"]
//        XCTAssertTrue(infoButton.waitForExistence(timeout: 2), "❌ Info button not found")
//        infoButton.click()
//
//        // 2️⃣ Verify that the sheet appears
//        let sheetTitle = app.staticTexts["Processed Files"]
//        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 2), "❌ Sheet title not found after clicking info")
//
//        // 3️⃣ Click the CLOSE button inside the sheet
//        let closeButton = app.buttons["closeButton"]
//        XCTAssertTrue(closeButton.waitForExistence(timeout: 2), "❌ Close button not found in sheet")
//        closeButton.click()
//
//        // 4️⃣ Verify the sheet disappears
//        XCTAssertFalse(sheetTitle.waitForExistence(timeout: 2), "❌ Sheet did not close after clicking close")
//    }
}
