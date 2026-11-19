import XCTest

final class MusicE2ETests: XCTestCase {
    @MainActor
    func testChosenMusicSurvivesRelaunchAndSessionCanMuteIt() {
        let app = XCUIApplication()
        app.launchArguments = ["-e2e"]
        app.launch()
        let cosmos = app.buttons["start.music.kosmos"]
        XCTAssertTrue(cosmos.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["start.music.kosmos"].isSelected)
        cosmos.tap()
        XCTAssertTrue(cosmos.isSelected)
        app.terminate()

        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.buttons["start.music.kosmos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["start.music.kosmos"].isSelected)
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
