import Foundation

enum Signal: Hashable {
    case phaseStarted(phaseIndex: Int)
    case sessionFinished
    case countdown
}

struct ScheduledSignal: Equatable {
    let at: Date
    let signal: Signal
}

struct PhaseAlert: Equatable {
    let at: Date
    let title: String
}

enum HapticCue: Equatable {
    case phaseStarted
    case breath
    case countdown
    case sessionFinished
}

enum AudioSessionEvent: Equatable {
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case outputLost
}

@MainActor
protocol SessionClock: AnyObject {
    var now: Date { get }
    func startTicking(_ onTick: @escaping @MainActor () -> Void)
    func stopTicking()
}

@MainActor
protocol SignalPlayer: AnyObject {
    func plan(_ signals: [ScheduledSignal])
    func cancelPlan()
    func endSession()
}

@MainActor
protocol MusicPlayer: AnyObject {
    func play(_ fileName: String)
    func fade(to volume: Float, over seconds: TimeInterval)
    func stop()
}

@MainActor
protocol HapticPlayer: AnyObject {
    func play(_ cue: HapticCue)
}

@MainActor
protocol AudioSessionEvents: AnyObject {
    func onEvent(_ handler: @escaping @MainActor (AudioSessionEvent) -> Void)
}

@MainActor
protocol PhaseNotifier: AnyObject {
    func requestAuthorization() async
    func replace(with alerts: [PhaseAlert])
    func cancelAll()
}

protocol HistoryStorage: AnyObject {
    func load() throws -> Data?
    func save(_ data: Data) throws
}
