import Foundation
import Observation

@MainActor
@Observable
final class SessionModel {
    static let finishedTitle = "Koniec sesji"

    private(set) var player: SessionPlayer
    private(set) var now: Date
    let setName: String
    private let set: ExerciseSet
    private let phaseNames: [String]
    private let clock: SessionClock
    private let signals: SignalPlayer
    private let notifier: PhaseNotifier
    private let history: SessionHistory
    private let haptics: HapticPlayer
    private var lastBeat: HapticBeat?
    private let figures: FigureCatalog?
    private var pausedByInterruption = false
    private var startedAt: Date?

    init(set: ExerciseSet, clock: SessionClock, signals: SignalPlayer, notifier: PhaseNotifier, audioEvents: AudioSessionEvents, history: SessionHistory, haptics: HapticPlayer, figures: FigureCatalog? = nil) {
        self.player = SessionPlayer(set: set)
        self.setName = set.name
        self.set = set
        self.phaseNames = set.groups.flatMap { $0.phases.map(\.name) }
        self.clock = clock
        self.signals = signals
        self.notifier = notifier
        self.history = history
        self.haptics = haptics
        self.figures = figures
        self.now = clock.now
        audioEvents.onEvent { [weak self] event in self?.handle(event) }
    }

    var remainingInPhase: TimeInterval { player.remainingInPhase(now: now) }
    var remainingInSession: TimeInterval { player.remainingInSession(now: now) }

    var currentStep: Int? { Self.step(of: player.state) }

    var isInProgress: Bool { currentStep != nil }

    var currentPhaseName: String? { currentStep.map { phaseNames[$0] } }

    var currentGroupPosition: String? {
        currentStep.map { PhaseText.groupPosition(player.steps[$0].groupIndex, of: set.groups.count) }
    }

    var currentPhaseDuration: TimeInterval? { currentStep.map { player.steps[$0].duration } }

    var currentBreath: BoxBreath? {
        guard let duration = currentPhaseDuration, PhaseKind(phaseName: currentPhaseName ?? "") == .relaxation else { return nil }
        return BoxBreath(elapsed: duration - remainingInPhase)
    }

    var hapticBeat: HapticBeat? {
        guard let step = currentStep, let duration = currentPhaseDuration else { return nil }
        return HapticBeat.at(step: step, kind: PhaseKind(phaseName: phaseNames[step]), remaining: remainingInPhase, duration: duration)
    }

    var currentGroupName: String? { currentStep.map { set.groups[player.steps[$0].groupIndex].name } }

    var currentFigureName: String? {
        guard let group = currentGroupName, let phase = currentPhaseName else { return nil }
        return figures?.assetName(group: group, kind: PhaseKind(phaseName: phase))
    }

    var currentInstructions: [PhaseLine] {
        guard let step = currentStep.map({ player.steps[$0] }) else { return [] }
        return PhaseText.lines(set.groups[step.groupIndex].phases[step.phaseIndex].instructions)
    }

    func start() { perform(playsNow: true) { $0.start(now: $1) } }
    func pause() { perform { $0.pause(now: $1) } }
    func resume() { perform { $0.resume(now: $1) } }
    func skip() { perform(playsNow: true) { $0.skip(now: $1) } }
    func stop() { perform { $0.stop(now: $1) } }
    func tick() { perform(replans: false) { $0.tick(now: $1) } }

    private func handle(_ event: AudioSessionEvent) {
        Log.sound.notice("zdarzenie audio: \(String(describing: event), privacy: .public)")
        switch event {
        case .interruptionBegan:
            guard Self.isRunning(player.state) else { return }
            pause()
            pausedByInterruption = true
        case .interruptionEnded(let shouldResume):
            if pausedByInterruption, shouldResume { resume() }
            pausedByInterruption = false
        case .outputLost:
            pausedByInterruption = false
            if Self.isRunning(player.state) { pause() }
        }
    }

    private func perform(playsNow: Bool = false, replans: Bool = true, _ action: (inout SessionPlayer, Date) -> [PlayerEvent]) {
        let before = player.state
        now = clock.now
        let events = action(&player, now)
        playHaptics(after: before)
        guard player.state != before else { return }
        pausedByInterruption = false
        switch player.state {
        case .running:
            let wasRunning = Self.isRunning(before)
            if before == .ready { startedAt = now }
            if replans || !wasRunning {
                signals.plan(signalNow(after: events, playsNow: playsNow) + upcomingSignals())
                notifier.replace(with: alerts())
            }
            if !wasRunning { clock.startTicking { [weak self] in self?.tick() } }
        case .finished:
            if playsNow { signals.plan([ScheduledSignal(at: now, signal: .sessionFinished)]) }
            endSession(phasesDone: player.steps.count)
        case .stopped:
            signals.cancelPlan()
            endSession(phasesDone: Self.step(of: before) ?? 0)
        case .paused, .ready:
            signals.cancelPlan()
            notifier.cancelAll()
            clock.stopTicking()
        }
        Log.session.notice("stan: \(String(describing: self.player.state), privacy: .public)")
    }

    private func playHaptics(after before: PlayerState) {
        let beat = hapticBeat
        defer { lastBeat = beat }
        if player.state == .finished, before != .finished { return haptics.play(.sessionFinished) }
        if let cue = HapticBeat.cue(from: lastBeat, to: beat) { haptics.play(cue) }
    }

    private func endSession(phasesDone: Int) {
        if let startedAt {
            history.append(SessionRecord(setName: setName, startedAt: startedAt, endedAt: now,
                completed: player.state == .finished, phasesDone: phasesDone, phasesTotal: player.steps.count))
        }
        startedAt = nil
        signals.endSession()
        notifier.cancelAll()
        clock.stopTicking()
    }

    private static func step(of state: PlayerState) -> Int? {
        switch state {
        case .running(let step, _), .paused(let step, _): step
        case .ready, .finished, .stopped: nil
        }
    }

    private static func isRunning(_ state: PlayerState) -> Bool {
        if case .running = state { return true }
        return false
    }

    private func signalNow(after events: [PlayerEvent], playsNow: Bool) -> [ScheduledSignal] {
        guard playsNow, case .phaseStarted(let step, _) = events.last else { return [] }
        return [ScheduledSignal(at: now, signal: signal(enteringStep: step))]
    }

    static let countdownSeconds: [TimeInterval] = [3, 2, 1]

    private func upcomingSignals() -> [ScheduledSignal] {
        player.upcomingPhaseEnds().flatMap { end in
            let countdown = Self.countdownSeconds
                .filter { $0 < player.steps[end.step].duration }
                .map { end.at.addingTimeInterval(-$0) }
                .filter { $0 > now }
                .map { ScheduledSignal(at: $0, signal: .countdown) }
            return countdown + [ScheduledSignal(at: end.at, signal: signal(enteringStep: end.step + 1))]
        }
    }

    private func signal(enteringStep step: Int) -> Signal {
        step < player.steps.count ? .phaseStarted(phaseIndex: player.steps[step].phaseIndex) : .sessionFinished
    }

    private func alerts() -> [PhaseAlert] {
        player.upcomingPhaseEnds().map { end in
            let next = end.step + 1
            return PhaseAlert(at: end.at, title: next < phaseNames.count ? phaseNames[next] : Self.finishedTitle)
        }
    }
}
