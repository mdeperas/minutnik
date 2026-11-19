import XCTest
@testable import Minutnik

final class PhaseTextTests: XCTestCase {
    func testTensePhaseShowsTenseAndCaution() {
        let lines = PhaseText.lines(PhaseInstructions(how: "krótko", tense: "napnij", caution: "uważaj", release: nil, feel: nil))
        XCTAssertEqual(lines, [PhaseLine(label: "Jak", text: "krótko"), PhaseLine(label: "Napnij", text: "napnij"), PhaseLine(label: "Uwaga", text: "uważaj")])
    }

    func testReleasePhaseShowsReleaseAndFeelAndFallsBackToHow() {
        XCTAssertEqual(PhaseText.lines(PhaseInstructions(how: nil, tense: nil, caution: nil, release: "puść", feel: "poczuj")),
            [PhaseLine(label: "Puść", text: "puść"), PhaseLine(label: "Poczuj", text: "poczuj")])
        XCTAssertEqual(PhaseText.lines(PhaseInstructions(how: "jak", tense: nil, caution: "", release: nil, feel: nil)),
            [PhaseLine(label: "Jak", text: "jak")])
        XCTAssertEqual(PhaseText.lines(nil), [])
    }

    func testGroupPositionAndSetSummaryCountOnlyMuscleGroups() {
        let step = { (name: String, seconds: Int) in ExerciseGroup(name: name, phases: [ExercisePhase(name: name, durationSeconds: seconds, instructions: nil)]) }
        let muscle = ExerciseGroup(name: "g", phases: [ExercisePhase(name: "Napinanie", durationSeconds: 10, instructions: nil),
                                                       ExercisePhase(name: "Rozluźnienie", durationSeconds: 50, instructions: nil)])
        let set = ExerciseSet(name: "x", groups: [step("Wstęp", 30)] + Array(repeating: muscle, count: 8) + [step("Relaks", 120), step("Powrót", 31)])
        XCTAssertNil(PhaseText.groupPosition(0, in: set))
        XCTAssertEqual(PhaseText.groupPosition(1, in: set), "Grupa 1 z 8")
        XCTAssertEqual(PhaseText.groupPosition(8, in: set), "Grupa 8 z 8")
        XCTAssertNil(PhaseText.groupPosition(10, in: set))
        XCTAssertEqual(PhaseText.summary(of: set), "8 grup · 12 min")
        XCTAssertEqual([1, 2, 5, 12, 22].map(PhaseText.groupCount), ["1 grupa", "2 grupy", "5 grup", "12 grup", "22 grupy"])
    }
}
