import XCTest
@testable import Minutnik

final class AppVersionTests: XCTestCase {
    func testLabelShowsVersionBuildAndCommit() {
        let version = AppVersion(info: ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "7", "MinutnikGitCommit": "abc1234"])
        XCTAssertEqual(version.label, "Wersja 1.0 (7) · abc1234")
    }

    func testMissingFieldsShowQuestionMarks() {
        XCTAssertEqual(AppVersion(info: [:]).label, "Wersja ? (?) · ?")
    }
}
