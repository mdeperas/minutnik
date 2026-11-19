import XCTest
@testable import Minutnik

final class BoxBreathTests: XCTestCase {
    func testStagesFollowFourSecondBoxFromPhaseStart() {
        let labels = [0, 3.99, 4, 8, 12, 16].map { BoxBreath(elapsed: $0).stage }
        XCTAssertEqual(labels, [.inhale, .inhale, .holdFull, .exhale, .holdEmpty, .inhale])
        XCTAssertEqual([0, 0.99, 1, 3.99].map { BoxBreath(elapsed: $0).secondsLeft }, [4, 4, 3, 1])
        XCTAssertEqual(BoxBreath(elapsed: 6).cycleProgress, 0.375, accuracy: 1e-9)
        XCTAssertEqual(BoxBreath(elapsed: 10).fullness, 0.5, accuracy: 1e-9)
    }

    func testLastPartialCycleOfFiftySecondsIsCutDuringInhale() {
        let last = BoxBreath(elapsed: 49.99)
        XCTAssertEqual(last.stage, .inhale)
        XCTAssertEqual(last.secondsLeft, 3)
        XCTAssertEqual(last.index, 12)
    }

    func testCueOnPhaseStartEveryBreathStageAndCountdownOnly() {
        let beat = { (step: Int, remaining: TimeInterval) in
            HapticBeat.at(step: step, kind: .relaxation, remaining: remaining, duration: 50)
        }
        XCTAssertEqual(HapticBeat.cue(from: beat(1, 46.1), to: beat(1, 45.9)), .breath)
        XCTAssertNil(HapticBeat.cue(from: beat(1, 46.9), to: beat(1, 46.1)))
        XCTAssertEqual(HapticBeat.cue(from: beat(1, 3.1), to: beat(1, 2.9)), .countdown)
        XCTAssertEqual(HapticBeat.cue(from: beat(0, 0.1), to: beat(1, 49.9)), .phaseStarted)
        XCTAssertEqual(HapticBeat.cue(from: nil, to: beat(0, 50)), .phaseStarted)
        XCTAssertNil(HapticBeat.cue(from: beat(1, 20), to: nil))
        XCTAssertNil(HapticBeat.cue(from: beat(1, 20), to: beat(1, 20)))
        let tension = { (remaining: TimeInterval) in HapticBeat.at(step: 0, kind: .tension, remaining: remaining, duration: 10) }
        XCTAssertNil(HapticBeat.cue(from: tension(6), to: tension(5)))
        XCTAssertEqual(HapticBeat.cue(from: tension(3.1), to: tension(2.9)), .countdown)
        XCTAssertEqual(HapticBeat.cue(from: tension(1.1), to: tension(0.9)), .countdown)
    }
}
