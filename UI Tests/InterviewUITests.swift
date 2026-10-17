import XCTest

final class InterviewUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testSelectingAnArticlePushesItsDetail() throws {
        let app = XCUIApplication()
        app.launch()

        let searchField = app.searchFields["Search titles"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 20))
        XCTAssertFalse(app.keyboards.element.exists)

        let article = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Wiggins")).firstMatch
        XCTAssertTrue(article.waitForExistence(timeout: 20))
        article.tap()

        let body = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Lorem ipsum")).firstMatch
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars.staticTexts["Articles"].exists)

        app.buttons["Back"].tap()
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertFalse(app.keyboards.element.exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
