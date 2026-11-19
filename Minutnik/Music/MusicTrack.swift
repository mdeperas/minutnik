import Foundation

enum MusicTrack: String, CaseIterable, Identifiable {
    case none = "bez"
    case synthwave
    case cosmos = "kosmos"
    case forest = "las"

    static let defaultsKey = "minutnik.muzyka"
    static let volume: Float = 0.3
    static let fadeSeconds: TimeInterval = 1.5

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "Bez"
        case .synthwave: "Synthwave"
        case .cosmos: "Kosmos"
        case .forest: "Las"
        }
    }

    var fileName: String? { self == .none ? nil : rawValue }

    init(stored: String?) {
        self = stored.flatMap(MusicTrack.init(rawValue:)) ?? .none
    }

    func volume(muted: Bool, state: PlayerState) -> Float {
        guard self != .none, !muted, case .running = state else { return 0 }
        return Self.volume
    }
}
