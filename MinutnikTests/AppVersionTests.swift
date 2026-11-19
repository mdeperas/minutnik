import XCTest
@testable import Minutnik

final class AppVersionTests: XCTestCase {
    func testLabelShowsVersionBuildCommitAndReleaseDate() {
        let version = AppVersion(info: ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "7", "MinutnikGitCommit": "abc1234", "MinutnikReleaseDate": "19.11.2026 14:05"])
        XCTAssertEqual(version.label, "Wersja 1.0 (7) · abc1234 · 19.11.2026 14:05")
    }

    func testMissingFieldsShowQuestionMarks() {
        XCTAssertEqual(AppVersion(info: [:]).label, "Wersja ? (?) · ? · ?")
    }
}
