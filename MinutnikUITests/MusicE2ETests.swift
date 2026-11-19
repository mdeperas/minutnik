import XCTest

final class MusicE2ETests: XCTestCase {
    @MainActor
    func testChosenMusicSurvivesRelaunchAndSessionCanMuteIt() {
        let app = XCUIApplication()
        app.launchArguments = ["-e2e"]
        app.launch()
        let forest = app.buttons["start.music.las"]
        XCTAssertTrue(forest.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["start.music.las"].isSelected)
        forest.tap()
        XCTAssertTrue(forest.isSelected)
        app.terminate()

        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.buttons["start.music.las"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["start.music.las"].isSelected)
        XCTAssertFalse(app.buttons["start.music.bez"].isSelected)

        app.buttons["start.set.0"].tap()
        let toggle = app.buttons["session.music"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.label, "Wycisz muzykę")
        app.buttons["session.start"].tap()
        toggle.tap()
        XCTAssertEqual(app.buttons["session.music"].label, "Włącz muzykę")
    }
}
