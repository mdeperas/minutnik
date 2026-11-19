import AVFoundation

@MainActor
final class ToneSignalPlayer: SignalPlayer {
    private static let silenceAfterLastSignal: TimeInterval = 3
    private static let staleAfter: TimeInterval = 0.5

    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var buffers: [Signal: AVAudioPCMBuffer] = [:]
    private var planned: [ScheduledSignal] = []
    private var generation = 0
    private var configurationObserver: NSObjectProtocol?

    init() {
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rescheduleAfterConfigurationChange() }
        }
    }

    func plan(_ signals: [ScheduledSignal]) {
        generation += 1
        planned = signals
        guard activate() else { return }
        schedule(signals)
    }

    func cancelPlan() {
        generation += 1
        planned = []
        node.stop()
    }

    func endSession() {
        generation += 1
        let current = generation
        let lastSignal = planned.map(\.at).max() ?? .distantPast
        let wait = max(0, lastSignal.timeIntervalSinceNow) + Self.silenceAfterLastSignal
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard let self, current == self.generation else { return }
            self.deactivate()
        }
    }

    private func activate() -> Bool {
        if engine.isRunning { return true }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            Log.sound.notice("sesja audio aktywna")
            return true
        } catch {
            Log.sound.error("dźwięk nie ruszył: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func deactivate() {
        planned = []
        node.stop()
        engine.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            Log.sound.notice("sesja audio wyłączona")
        } catch {
            Log.sound.error("sesja audio nie wyłączona: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func schedule(_ signals: [ScheduledSignal]) {
        node.stop()
        node.play()
        let hostNow = mach_absolute_time()
        for scheduled in signals.sorted(by: { $0.at < $1.at }) {
            let delay = scheduled.at.timeIntervalSinceNow
            guard delay > -Self.staleAfter else { continue }
            let when = delay > 0 ? AVAudioTime(hostTime: hostNow + AVAudioTime.hostTime(forSeconds: delay)) : nil
            node.scheduleBuffer(buffer(for: scheduled.signal), at: when)
        }
    }

    private func buffer(for signal: Signal) -> AVAudioPCMBuffer {
        if let cached = buffers[signal] { return cached }
        let made = Tone.buffer(for: signal, format: format)
        buffers[signal] = made
        return made
    }

    private func rescheduleAfterConfigurationChange() {
        guard !planned.isEmpty else { return }
        Log.sound.notice("zmiana konfiguracji audio, planuję od nowa")
        guard activate() else { return }
        schedule(planned.filter { $0.at.timeIntervalSinceNow > 0 })
    }
}
