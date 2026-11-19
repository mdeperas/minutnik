import Foundation

final class FileHistoryStorage: HistoryStorage {
    private let url: URL

    init(url: URL = FileHistoryStorage.defaultURL) { self.url = url }

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appendingPathComponent("historia.json")
    }

    func load() throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    func save(_ data: Data) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
