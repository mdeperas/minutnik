import XCTest
@testable import Minutnik

final class PhaseTextTests: XCTestCase {
    func testTensePhaseShowsTenseAndCaution() {
        let lines = PhaseText.lines(PhaseInstructions(how: "krótko", tense: "napnij", caution: "uważaj", release: nil, feel: nil))
        XCTAssertEqual(lines, [PhaseLine(label: "Napnij", text: "napnij"), PhaseLine(label: "Uwaga", text: "uważaj")])
    }

    func testReleasePhaseShowsReleaseAndFeelAndFallsBackToHow() {
        XCTAssertEqual(PhaseText.lines(PhaseInstructions(how: nil, tense: nil, caution: nil, release: "puść", feel: "poczuj")),
            [PhaseLine(label: "Puść", text: "puść"), PhaseLine(label: "Poczuj", text: "poczuj")])
        XCTAssertEqual(PhaseText.lines(PhaseInstructions(how: "jak", tense: nil, caution: "", release: nil, feel: nil)),
            [PhaseLine(label: "Jak", text: "jak")])
        XCTAssertEqual(PhaseText.lines(nil), [])
    }

    func testGroupPositionAndSetSummary() {
        XCTAssertEqual(PhaseText.groupPosition(0, of: 12), "Grupa 1 z 12")
        XCTAssertEqual([1, 2, 5, 12, 22].map(PhaseText.groupCount), ["1 grupa", "2 grupy", "5 grup", "12 grup", "22 grupy"])
        let set = ExerciseSet(name: "x", groups: (1...8).map { _ in
            ExerciseGroup(name: "g", phases: [ExercisePhase(name: "a", durationSeconds: 10, instructions: nil),
                                              ExercisePhase(name: "b", durationSeconds: 50, instructions: nil)])
        } + [ExerciseGroup(name: "g", phases: [ExercisePhase(name: "a", durationSeconds: 1, instructions: nil)])])
        XCTAssertEqual(PhaseText.summary(of: set), "9 grup · 9 min")
    }
}
