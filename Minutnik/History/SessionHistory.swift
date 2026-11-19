import Foundation
import Observation

@MainActor
@Observable
final class SessionHistory {
    private(set) var records: [SessionRecord]
    private let storage: HistoryStorage
    private var keepsUnreadableFile = false

    init(storage: HistoryStorage) {
        self.storage = storage
        do {
            records = try storage.load().map(HistoryCodec.decode) ?? []
        } catch {
            Log.session.error("historia nieczytelna: \(error.localizedDescription, privacy: .public)")
            records = []
            keepsUnreadableFile = true
        }
    }

    var newestFirst: [SessionRecord] { records.reversed() }

    func append(_ record: SessionRecord) {
        records.append(record)
        guard !keepsUnreadableFile else { return }
        do {
            try storage.save(HistoryCodec.encode(records))
        } catch {
            Log.session.error("zapis historii: \(error.localizedDescription, privacy: .public)")
        }
    }
}
