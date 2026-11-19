import AudioToolbox
import CoreHaptics

@MainActor
final class CoreHapticPlayer: HapticPlayer {
    private let engine: CHHapticEngine?
    private var engineRunning = false

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            engine = nil
            return
        }
        engine = try? CHHapticEngine()
        engine?.playsHapticsOnly = true
        engine?.isAutoShutdownEnabled = false
        engine?.stoppedHandler = { [weak self] reason in
            Task { @MainActor in
                self?.engineRunning = false
                Log.sound.notice("silnik haptyki stanął: \(reason.rawValue, privacy: .public)")
            }
        }
        engine?.resetHandler = { [weak self] in
            Task { @MainActor in self?.restartAfterReset() }
        }
    }

    private func restartAfterReset() {
        engineRunning = (try? engine?.start()) != nil
    }

    func play(_ cue: HapticCue) {
        guard let engine else { return }
        do {
            if !engineRunning {
                try engine.start()
                engineRunning = true
            }
            try engine.makePlayer(with: Self.pattern(for: cue)).start(atTime: CHHapticTimeImmediate)
        } catch {
            engineRunning = false
            Log.sound.error("haptyka nie ruszyła: \(error.localizedDescription, privacy: .public)")
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private static func pattern(for cue: HapticCue) throws -> CHHapticPattern {
        let taps: [(TimeInterval, Float)] = switch cue {
        case .breath: [(0, 0.7)]
        case .countdown: [(0, 1)]
        case .phaseStarted: [(0, 1), (0.12, 1)]
        case .sessionFinished: [(0, 1), (0.15, 1), (0.3, 1)]
        }
        let events = taps.map { time, intensity in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
            ], relativeTime: time)
        }
        return try CHHapticPattern(events: events, parameters: [])
    }
}
