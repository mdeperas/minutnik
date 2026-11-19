import XCTest
@testable import Minutnik

final class ClockTextTests: XCTestCase {
    func testRoundsUpToWholeSecondsAsMinutesSeconds() {
        XCTAssertEqual([0, 0.2, 59.1, 60, 3599].map(ClockText.minutesSeconds), ["0:00", "0:01", "1:00", "1:00", "59:59"])
    }
}
