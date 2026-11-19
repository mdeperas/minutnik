import XCTest

final class ReadingE2ETests: XCTestCase {
    @MainActor
    func testAboutScreenScrollsAndGoesBackToStart() {
        let app = XCUIApplication()
        app.launchArguments = ["-e2e"]
        app.launch()
        let about = app.buttons["start.about"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        XCTAssertTrue(about.isHittable)
        about.tap()

        XCTAssertTrue(app.navigationBars["O ćwiczeniu"].waitForExistence(timeout: 5))
        let source = app.staticTexts["reading.source"]
        XCTAssertFalse(source.exists && source.isHittable)
        for _ in 0..<8 where !(source.exists && source.isHittable) {
            app.scrollViews.firstMatch.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(source.isHittable)
        XCTAssertTrue(source.label.contains("Ponad lękiem"))

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["start.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(about.isHittable)
        XCTAssertTrue(app.buttons["start.set.0"].isHittable)
    }
}
