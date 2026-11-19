import XCTest
@testable import Minutnik

final class SessionRecordTests: XCTestCase {
    private let record = SessionRecord(setName: "PRM", startedAt: Date(timeIntervalSince1970: 0),
        endedAt: Date(timeIntervalSince1970: 750), completed: false, phasesDone: 5, phasesTotal: 24)

    func testExportJsonUsesIsoDatesAndRoundTrips() throws {
        let data = try HistoryCodec.encode([record])
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("\"startedAt\" : \"1970-01-01T00:00:00Z\""), text)
        XCTAssertTrue(text.contains("\"completed\" : false"), text)
        XCTAssertEqual(try HistoryCodec.decode(data), [record])
    }

    func testSummaryShowsOutcomeAndMinutes() {
        XCTAssertEqual(HistoryText.summary(of: record), "Przerwana po 5 z 24 faz · 13 min")
        let done = SessionRecord(setName: "PRM", startedAt: record.startedAt, endedAt: Date(timeIntervalSince1970: 720),
            completed: true, phasesDone: 24, phasesTotal: 24)
        XCTAssertEqual(HistoryText.summary(of: done), "Ukończona · 12 min")
    }
}
