#if targetEnvironment(simulator)
import Foundation

@MainActor
enum SimulatedEnvironment {
    static let timeScaleKey = "MINUTNIK_E2E_TIME_SCALE"
    private static let configSuite = "e2e"
    private static let activeKey = "active"

    static func fromLaunch(_ process: ProcessInfo = .processInfo) -> AppEnvironment? {
        guard let config = UserDefaults(suiteName: configSuite) else { return nil }
        let arguments = process.arguments
        if arguments.contains("-e2e-off") {
            config.removePersistentDomain(forName: configSuite)
            return nil
        }
        if arguments.contains("-e2e") {
            config.removePersistentDomain(forName: configSuite)
            config.set(true, forKey: activeKey)
            if let scale = process.environment[timeScaleKey].flatMap(Double.init), scale > 0 {
                config.set(scale, forKey: timeScaleKey)
            }
        }
        guard config.bool(forKey: activeKey) else { return nil }
        let scale = config.double(forKey: timeScaleKey)
        return AppEnvironment(
            version: AppVersion(info: ["CFBundleShortVersionString": "e2e"]),
            clock: AcceleratedClock(scale: scale > 0 ? scale : 1),
            signals: RecordingSignalPlayer(),
            notifier: RecordingPhaseNotifier(),
            audioEvents: RecordingAudioEvents(),
            catalog: Result { try ExerciseCatalog.bundled() },
            history: SessionHistory(storage: InMemoryHistoryStorage()),
            haptics: RecordingHapticPlayer(),
            figures: FigureCatalog.bundled()
        )
    }
}

@MainActor
final class AcceleratedClock: SessionClock {
    private let scale: Double
    private let origin: Date
    private let realNow: () -> Date
    private let ticker = SystemClock()

    init(scale: Double, realNow: @escaping () -> Date = Date.init) {
        self.scale = scale
        self.realNow = realNow
        self.origin = realNow()
    }

    var now: Date { origin.addingTimeInterval(realNow().timeIntervalSince(origin) * scale) }

    func startTicking(_ onTick: @escaping @MainActor () -> Void) { ticker.startTicking(onTick) }
    func stopTicking() { ticker.stopTicking() }
}

#endif
