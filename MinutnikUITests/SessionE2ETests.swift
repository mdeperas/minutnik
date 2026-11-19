import XCTest

final class SessionE2ETests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-e2e"]
        app.launch()
    }

    @MainActor
    func testListShowsSetsWithSummary() {
        let first = app.buttons["start.set.0"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(first.label.contains("12 grup · 15 min"), first.label)
        XCTAssertFalse(app.buttons["start.set.1"].exists)
    }

    @MainActor
    func testRunPauseSkipAndStopFirstSet() {
        app.buttons["start.set.0"].tap()
        app.buttons["session.start"].tap()
        let remaining = app.staticTexts["session.remainingPhase"]
        XCTAssertTrue(remaining.waitForExistence(timeout: 5))
        XCTAssertTrue(remaining.label.hasPrefix("Zostało "))
        XCTAssertEqual(app.staticTexts["session.group"].label, "Wstęp")
        XCTAssertFalse(app.staticTexts["session.groupPosition"].exists)
        app.buttons["session.skip"].tap()
        XCTAssertEqual(app.staticTexts["session.groupPosition"].label, "Grupa 1 z 12")
        XCTAssertEqual(app.staticTexts["session.group"].label, "Przedramiona")
        app.buttons["session.pause"].tap()
        XCTAssertTrue(app.buttons["session.resume"].waitForExistence(timeout: 5))
        let phaseBefore = app.staticTexts["session.phase"].label
        app.buttons["session.skip"].tap()
        XCTAssertNotEqual(app.staticTexts["session.phase"].label, phaseBefore)
        XCTAssertTrue(app.buttons["session.pause"].exists)
        app.buttons["session.stop"].tap()
        XCTAssertEqual(app.staticTexts["session.phase"].label, "Przerwano")
        app.buttons["session.done"].tap()
        XCTAssertTrue(app.buttons["start.set.0"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNoBackDuringSessionAndPauseLeadsBackToList() {
        app.buttons["start.set.0"].tap()
        app.buttons["session.start"].tap()
        XCTAssertEqual(app.navigationBars.buttons.count, 0)
        app.buttons["session.pause"].tap()
        XCTAssertTrue(app.buttons["session.resume"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.navigationBars.buttons.count, 0)
        app.buttons["session.stop"].tap()
        app.buttons["session.done"].tap()
        XCTAssertTrue(app.buttons["start.set.0"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSkippingAllPhasesEndsSessionAfterRelaxAndReturn() {
        app.buttons["start.set.0"].tap()
        app.buttons["session.start"].tap()
        for _ in 0..<25 { app.buttons["session.skip"].tap() }
        XCTAssertEqual(app.staticTexts["session.group"].label, "Pełny relaks")
        XCTAssertEqual(app.staticTexts["session.phase"].label, "Relaks")
        XCTAssertTrue(app.descendants(matching: .any)["session.breath"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["session.groupPosition"].exists)
        app.buttons["session.skip"].tap()
        XCTAssertEqual(app.staticTexts["session.group"].label, "Powrót")
        app.buttons["session.skip"].tap()
        XCTAssertTrue(app.buttons["session.done"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["session.phase"].label, "Koniec sesji")
        app.buttons["session.done"].tap()
        XCTAssertTrue(app.buttons["start.set.0"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["history.row.0"].exists)
        XCTAssertFalse(app.staticTexts["Historia"].exists)
    }

    @MainActor
    func testFigureFollowsPhase() throws {
        app.buttons["start.set.0"].tap()
        app.buttons["session.start"].tap()
        app.buttons["session.skip"].tap()
        app.buttons["session.pause"].tap()
        XCTAssertTrue(app.buttons["session.resume"].waitForExistence(timeout: 5))
        let figure = app.images["session.figure"]
        XCTAssertTrue(figure.waitForExistence(timeout: 5))
        let tensed = figure.value as? String ?? ""
        XCTAssertTrue(tensed.hasSuffix("-napiecie"), tensed)
        let folder = URL(fileURLWithPath: "/tmp/minutnik-wyglad")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: folder.appendingPathComponent("ios-rycina.png"))
        app.buttons["session.skip"].tap()
        XCTAssertEqual(figure.value as? String, tensed.replacingOccurrences(of: "-napiecie", with: "-rozluznienie"))
    }

    @MainActor
    func testRelaxationShowsBoxBreathAndFigureZooms() {
        app.buttons["start.set.0"].tap()
        app.buttons["session.start"].tap()
        app.buttons["session.skip"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["session.breath"].exists)
        app.buttons["session.skip"].tap()
        let breath = app.descendants(matching: .any)["session.breath"]
        XCTAssertTrue(breath.waitForExistence(timeout: 5))
        XCTAssertTrue(breath.label.hasPrefix("Oddech: Wdech"), breath.label)
        XCTAssertTrue(app.staticTexts["session.remainingPhase"].exists)
        XCTAssertTrue(app.staticTexts["session.phase"].label.hasPrefix("Rozluźni"), app.staticTexts["session.phase"].label)
        app.images["session.figure"].tap()
        XCTAssertTrue(app.images["session.figureZoomed"].waitForExistence(timeout: 5))
        app.images["session.figureZoomed"].tap()
        XCTAssertTrue(app.images["session.figureZoomed"].waitForNonExistence(timeout: 5))
    }

    @MainActor
    func testSessionFitsWithPwaSizedRing() throws {
        app.buttons["start.set.0"].tap()
        app.buttons["session.start"].tap()
        app.buttons["session.skip"].tap()
        let ring = app.descendants(matching: .any)["session.ring"]
        let instructions = app.descendants(matching: .any)["session.instructions"]
        for name in ["napinanie", "rozluznienie"] {
            XCTAssertTrue(ring.waitForExistence(timeout: 5))
            let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["MINUTNIK_ZRZUTY"] ?? NSTemporaryDirectory())
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: folder.appendingPathComponent("minutnik-porownanie-\(name)-ios.png"))
            XCTAssertGreaterThanOrEqual(ring.frame.height, 100, name)
            XCTAssertLessThanOrEqual(instructions.frame.maxY, app.buttons["session.pause"].frame.minY, name)
            let more = app.buttons["session.instructionsMore"]
            if more.exists {
                more.tap()
                let expanded = app.descendants(matching: .any)["session.instructionsExpanded"].firstMatch
                XCTAssertTrue(expanded.waitForExistence(timeout: 5), name)
                expanded.tap()
                XCTAssertTrue(expanded.waitForNonExistence(timeout: 5), name)
            }
            app.buttons["session.skip"].tap()
        }
    }
}
