import XCTest
@testable import Minutnik

final class ToneTests: XCTestCase {
    func testSignalsAreDistinguishable() {
        XCTAssertEqual(Tone.beeps(for: .phaseStarted(phaseIndex: 0)).map(\.frequency), [880])
        XCTAssertEqual(Tone.beeps(for: .phaseStarted(phaseIndex: 1)).map(\.frequency), [660])
        XCTAssertEqual(Tone.beeps(for: .sessionFinished).map(\.frequency), [660, 880, 1_100])
    }
}
