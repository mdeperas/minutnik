import XCTest

final class StartScreenE2ETests: XCTestCase {
    @MainActor
    func testStartScreenShowsAppName() {
        let app = XCUIApplication()
        app.launchArguments = ["-e2e"]
        app.launch()
        XCTAssertTrue(app.staticTexts["start.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["start.title"].label, "Minutnik")
    }
}
