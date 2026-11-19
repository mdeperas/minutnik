import XCTest
@testable import Minutnik

@MainActor
final class AcceleratedClockTests: XCTestCase {
    func testScalesElapsedRealTime() {
        var real = Date(timeIntervalSinceReferenceDate: 500)
        let clock = AcceleratedClock(scale: 20, realNow: { real })
        real = real.addingTimeInterval(1.5)
        XCTAssertEqual(clock.now, Date(timeIntervalSinceReferenceDate: 530))
    }
}
