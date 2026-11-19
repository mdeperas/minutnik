import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct SessionRecord: Codable, Equatable {
    let setName: String
    let startedAt: Date
    let endedAt: Date
    let completed: Bool
    let phasesDone: Int
    let phasesTotal: Int
}

enum HistoryCodec {
    static func encode(_ records: [SessionRecord]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(records)
    }

    static func decode(_ data: Data) throws -> [SessionRecord] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([SessionRecord].self, from: data)
    }
}

enum HistoryText {
    static func summary(of record: SessionRecord) -> String {
        let minutes = Int((record.endedAt.timeIntervalSince(record.startedAt) / 60).rounded())
        let outcome = record.completed ? "Ukończona" : "Przerwana po \(record.phasesDone) z \(record.phasesTotal) faz"
        return "\(outcome) · \(minutes) min"
    }
}

struct HistoryExport: Transferable {
    static let fileName = "minutnik-historia.json"
    let records: [SessionRecord]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { try HistoryCodec.encode($0.records) }
            .suggestedFileName(fileName)
    }
}
