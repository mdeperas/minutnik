import Foundation

@MainActor
struct AppEnvironment {
    let version: AppVersion
    let clock: SessionClock
    let signals: SignalPlayer
    let notifier: PhaseNotifier
    let audioEvents: AudioSessionEvents
    let catalog: Result<ExerciseCatalog, Error>
    let history: SessionHistory
    let haptics: HapticPlayer
    let figures: FigureCatalog?
    var about: Result<ReadingText, Error> = .failure(ReadingTextError.missingFile)

    static var current: AppEnvironment {
        #if targetEnvironment(simulator)
        if let simulated = SimulatedEnvironment.fromLaunch() { return simulated }
        #endif
        return production
    }

    static var production: AppEnvironment {
        AppEnvironment(
            version: AppVersion(), clock: SystemClock(), signals: ToneSignalPlayer(), notifier: LocalPhaseNotifier(),
            audioEvents: SystemAudioSessionEvents(),
            catalog: Result { try ExerciseCatalog.bundled() },
            history: SessionHistory(storage: FileHistoryStorage()),
            haptics: CoreHapticPlayer(),
            figures: FigureCatalog.bundled(),
            about: Result { try ReadingText.bundled() }
        )
    }

    func makeSession(_ set: ExerciseSet) -> SessionModel {
        SessionModel(set: set, clock: clock, signals: signals, notifier: notifier, audioEvents: audioEvents, history: history, haptics: haptics, figures: figures)
    }
}
