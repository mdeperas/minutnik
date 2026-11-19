#if targetEnvironment(simulator)
import Foundation

@MainActor
final class RecordingSignalPlayer: SignalPlayer {
    private(set) var plans: [[ScheduledSignal]] = []
    private(set) var pending: [ScheduledSignal] = []
    private(set) var endedCount = 0

    func plan(_ signals: [ScheduledSignal]) {
        plans.append(signals)
        pending = signals
    }

    func cancelPlan() { pending = [] }

    func endSession() { endedCount += 1 }
}

@MainActor
final class RecordingAudioEvents: AudioSessionEvents {
    private var handler: (@MainActor (AudioSessionEvent) -> Void)?

    func onEvent(_ handler: @escaping @MainActor (AudioSessionEvent) -> Void) { self.handler = handler }

    func emit(_ event: AudioSessionEvent) { handler?(event) }
}

@MainActor
final class RecordingPhaseNotifier: PhaseNotifier {
    private(set) var pending: [PhaseAlert] = []
    private(set) var cancelCount = 0
    private(set) var authorizationRequests = 0

    func requestAuthorization() async { authorizationRequests += 1 }

    func replace(with alerts: [PhaseAlert]) { pending = alerts }

    func cancelAll() {
        pending = []
        cancelCount += 1
    }
}
final class InMemoryHistoryStorage: HistoryStorage {
    private(set) var data: Data?

    func load() throws -> Data? { data }
    func save(_ data: Data) throws { self.data = data }
}
#endif
