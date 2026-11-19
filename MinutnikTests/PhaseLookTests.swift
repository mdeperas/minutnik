import XCTest
@testable import Minutnik

final class PhaseLookTests: XCTestCase {
    func testTensionRingDrainsAndShrinksFromFullAtStart() {
        let start = PhaseLook(phaseName: "Napinanie", remaining: 10, duration: 10, reduceMotion: false)
        XCTAssertEqual(start.kind, .tension)
        XCTAssertEqual(start.remainingFraction, 1)
        XCTAssertEqual(start.scale, 1)
        XCTAssertEqual(start.digits, "10")
        let late = PhaseLook(phaseName: "Napinanie", remaining: 2.5, duration: 10, reduceMotion: false)
        XCTAssertEqual(late.remainingFraction, 0.25, accuracy: 1e-9)
        XCTAssertEqual(late.scale, 0.85, accuracy: 1e-9)
        XCTAssertEqual(late.digits, "3")
    }

    func testRelaxationRingGrowsBackAndReduceMotionKeepsItStill() {
        let half = PhaseLook(phaseName: "Rozluźnienie", remaining: 25, duration: 50, reduceMotion: false)
        XCTAssertEqual(half.kind, .relaxation)
        XCTAssertEqual(half.scale, 0.9, accuracy: 1e-9)
        let still = PhaseLook(phaseName: "Rozluźnienie", remaining: 25, duration: 50, reduceMotion: true)
        XCTAssertEqual(still.scale, 1)
        XCTAssertEqual(still.remainingFraction, 0.5, accuracy: 1e-9)
        let overdue = PhaseLook(phaseName: "Rozluźnienie", remaining: -1, duration: 50, reduceMotion: false)
        XCTAssertEqual(overdue.remainingFraction, 0)
        XCTAssertEqual(overdue.digits, "0")
        XCTAssertEqual(PhaseLook(phaseName: "x", remaining: 75, duration: 90, reduceMotion: false).digits, "1:15")
    }

    func testColorsMatchWebTimerPerPhase() {
        XCTAssertEqual(PhaseKind.tension.ringColor.hex, 0x5AD4ED)
        XCTAssertEqual(PhaseKind.tension.labelColor.hex, 0xB1EFFB)
        XCTAssertEqual(PhaseKind.relaxation.ringColor.hex, 0x8FBFA3)
        XCTAssertEqual(PhaseKind.relaxation.labelColor.hex, 0x8FBFA3)
        XCTAssertEqual(PhaseLook.background.hex, 0x17181C)
    }

    func testOnlyInstructionsOfCurrentPhaseAreHighlighted() {
        XCTAssertEqual(["Napnij", "Uwaga", "Jak"].map(PhaseKind.tension.highlights), [true, false, false])
        XCTAssertEqual(["Puść", "Poczuj", "Jak"].map(PhaseKind.relaxation.highlights), [true, true, false])
    }
}

private extension LookColor {
    var hex: UInt32 {
        [red, green, blue].reduce(0) { $0 << 8 | UInt32(($1 * 255).rounded()) }
    }
}
