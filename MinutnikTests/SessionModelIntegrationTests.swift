import XCTest
@testable import Minutnik

@MainActor
final class ManualClock: SessionClock {
    private(set) var now: Date
    private var onTick: (@MainActor () -> Void)?

    init(now: Date) { self.now = now }

    var isTicking: Bool { onTick != nil }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
        onTick?()
    }

    func startTicking(_ onTick: @escaping @MainActor () -> Void) { self.onTick = onTick }
    func stopTicking() { onTick = nil }
}

@MainActor
final class SessionModelIntegrationTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 1_000)
    private var clock: ManualClock!
    private var signals: RecordingSignalPlayer!
    private var notifier: RecordingPhaseNotifier!
    private var audio: RecordingAudioEvents!
    private var model: SessionModel!
    private var storage: InMemoryHistoryStorage!
    private var history: SessionHistory!
    private var haptics: RecordingHapticPlayer!

    override func setUp() async throws {
        clock = ManualClock(now: t0)
        signals = RecordingSignalPlayer()
        notifier = RecordingPhaseNotifier()
        audio = RecordingAudioEvents()
        storage = InMemoryHistoryStorage()
        history = SessionHistory(storage: storage)
        haptics = RecordingHapticPlayer()
        let set = ExerciseSet(name: "Test", groups: (1...3).map { group in
            ExerciseGroup(name: "Grupa \(group)", phases: [
                ExercisePhase(name: "Napinanie \(group)", durationSeconds: 10, instructions: nil),
                ExercisePhase(name: "Rozluźnij \(group)", durationSeconds: 50, instructions: nil),
            ])
        })
        model = AppEnvironment(version: AppVersion(info: [:]), clock: clock, signals: signals, notifier: notifier,
            audioEvents: audio, catalog: .failure(ExerciseCatalogError.missingFile), history: history, haptics: haptics,
            figures: try! FigureCatalog(json: Data(#"{"Grupa 1": {"napiecie": "g1-n.svg", "rozluznienie": "g1-r.svg"}}"#.utf8)),
            music: RecordingMusicPlayer(), settings: UserDefaults(suiteName: "minutnik-tests")!
        ).makeSession(set)
    }

    private func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    private let tense = Signal.phaseStarted(phaseIndex: 0)
    private let release = Signal.phaseStarted(phaseIndex: 1)

    private func planned(_ entries: [(TimeInterval, Signal)]) -> [ScheduledSignal] {
        entries.map { ScheduledSignal(at: at($0.0), signal: $0.1) }
    }

    private var phaseSignals: [ScheduledSignal] {
        signals.pending.filter { $0.signal != .countdown }
    }

    private var fullPlanFromStart: [ScheduledSignal] {
        planned([(0, tense), (10, release), (60, tense), (70, release), (120, tense), (130, release), (180, .sessionFinished)])
    }

    func testLastThreeSecondsOfEveryPhaseAreCountedDown() {
        model.start()
        let countdown = signals.pending.filter { $0.signal == .countdown }.map(\.at)
        XCTAssertEqual(countdown.prefix(6), [at(7), at(8), at(9), at(57), at(58), at(59)][...])
        XCTAssertEqual(countdown.count, 18)
        clock.advance(by: 8.5)
        model.pause()
        model.resume()
        XCTAssertEqual(signals.pending.first, ScheduledSignal(at: at(9), signal: .countdown))
    }

    func testHapticsTapOnPhaseStartEveryBreathStageAndCountdownButNotOnPauseOrStop() {
        model.start()
        for _ in 0..<60 { clock.advance(by: 1) }
        let breaths = Array(repeating: HapticCue.breath, count: 11)
        let countdown = Array(repeating: HapticCue.countdown, count: 3)
        XCTAssertEqual(haptics.played, [.phaseStarted] + countdown + [.phaseStarted] + breaths + countdown + [.phaseStarted])
        let before = haptics.played.count
        model.pause()
        model.resume()
        XCTAssertEqual(haptics.played.count, before)
        model.pause()
        model.skip()
        XCTAssertEqual(haptics.played.last, .phaseStarted)
        XCTAssertEqual(haptics.played.count, before + 1)
        model.stop()
        XCTAssertEqual(haptics.played.count, before + 1)
    }

    func testSessionEndTapsSuccessOnce() {
        model.start()
        for _ in 0..<185 { clock.advance(by: 1) }
        XCTAssertEqual(haptics.played.last, .sessionFinished)
        XCTAssertEqual(haptics.played.filter { $0 == .sessionFinished }.count, 1)
    }

    func testFigureFollowsPhaseAndDisappearsForUnmappedGroup() {
        XCTAssertNil(model.currentFigureName)
        model.start()
        XCTAssertEqual(model.currentFigureName, "g1-n")
        model.skip()
        XCTAssertEqual(model.currentFigureName, "g1-r")
        model.skip()
        XCTAssertNil(model.currentFigureName)
    }

    func testStartPlansWholeSessionOnAudioTimelineAndTicks() {
        model.start()
        XCTAssertEqual(phaseSignals, fullPlanFromStart)
        XCTAssertEqual(notifier.pending.map(\.at), [10, 60, 70, 120, 130, 180].map(at))
        XCTAssertEqual(notifier.pending.first?.title, "Rozluźnij 1")
        XCTAssertEqual(notifier.pending.last?.title, SessionModel.finishedTitle)
        XCTAssertTrue(clock.isTicking)
    }

    func testTicksNeitherReplanNorPlaySignals() {
        model.start()
        clock.advance(by: 5)
        clock.advance(by: 5.2)
        clock.advance(by: 75)
        XCTAssertEqual(signals.plans.count, 1)
        XCTAssertEqual(phaseSignals, fullPlanFromStart)
        XCTAssertEqual(model.player.state, .running(step: 3, startedAt: at(70)))
        XCTAssertEqual(model.remainingInPhase, 34.8, accuracy: 0.001)
    }

    func testNaturalEndKeepsPlanAndEndsAudioSessionOnce() {
        model.start()
        for _ in 0..<200 { clock.advance(by: 1) }
        XCTAssertEqual(model.player.state, .finished)
        XCTAssertEqual(signals.plans.count, 1)
        XCTAssertEqual(signals.endedCount, 1)
        XCTAssertEqual(notifier.pending, [])
        XCTAssertFalse(clock.isTicking)
    }

    func testPauseCancelsPlanResumeReplansFromNowWithoutSoundNow() {
        model.start()
        clock.advance(by: 4)
        model.pause()
        XCTAssertEqual(phaseSignals, [])
        XCTAssertEqual(notifier.pending, [])
        XCTAssertFalse(clock.isTicking)
        clock.advance(by: 100)
        XCTAssertEqual(model.remainingInPhase, 6, accuracy: 0.001)
        model.resume()
        XCTAssertEqual(phaseSignals, planned([(110, release), (160, tense), (170, release), (220, tense), (230, release), (280, .sessionFinished)]))
        XCTAssertEqual(notifier.pending.first?.at, at(110))
        XCTAssertTrue(clock.isTicking)
        XCTAssertEqual(signals.endedCount, 0)
    }

    func testSkipPlaysNextSignalNowAndReplans() {
        model.start()
        clock.advance(by: 3)
        model.skip()
        XCTAssertEqual(phaseSignals.prefix(2), planned([(3, release), (53, tense)])[...])
        XCTAssertEqual(phaseSignals.count, 6)
        XCTAssertEqual(notifier.pending.count, 5)
    }

    func testSkipWhilePausedRunsAgainWithPlan() {
        model.start()
        model.pause()
        model.skip()
        XCTAssertEqual(model.player.state, .running(step: 1, startedAt: at(0)))
        XCTAssertEqual(phaseSignals.first, ScheduledSignal(at: at(0), signal: release))
        XCTAssertEqual(notifier.pending.count, 5)
        XCTAssertTrue(clock.isTicking)
    }

    func testSkipLastPhasePlaysFinishNowAndEndsSession() {
        model.start()
        for _ in 0..<5 { model.skip() }
        model.skip()
        XCTAssertEqual(model.player.state, .finished)
        XCTAssertEqual(phaseSignals, [ScheduledSignal(at: at(0), signal: .sessionFinished)])
        XCTAssertEqual(signals.endedCount, 1)
    }

    func testStopCancelsPlanAndEndsSessionWithoutSound() {
        model.start()
        clock.advance(by: 2)
        model.stop()
        XCTAssertEqual(model.player.state, .stopped)
        XCTAssertEqual(phaseSignals, [])
        XCTAssertEqual(signals.endedCount, 1)
        XCTAssertEqual(notifier.pending, [])
        XCTAssertFalse(clock.isTicking)
    }

    func testInterruptionPausesAndShouldResumeReplansFromNow() {
        model.start()
        clock.advance(by: 4)
        audio.emit(.interruptionBegan)
        XCTAssertEqual(model.player.state, .paused(step: 0, elapsed: 4))
        XCTAssertEqual(phaseSignals, [])
        clock.advance(by: 30)
        audio.emit(.interruptionEnded(shouldResume: true))
        XCTAssertEqual(model.player.state, .running(step: 0, startedAt: at(30)))
        XCTAssertEqual(phaseSignals.first, ScheduledSignal(at: at(40), signal: release))
    }

    func testInterruptionEndWithoutShouldResumeStaysPaused() {
        model.start()
        audio.emit(.interruptionBegan)
        audio.emit(.interruptionEnded(shouldResume: false))
        XCTAssertEqual(model.player.state, .paused(step: 0, elapsed: 0))
    }

    func testInterruptionDuringUserPauseDoesNotResume() {
        model.start()
        model.pause()
        audio.emit(.interruptionBegan)
        audio.emit(.interruptionEnded(shouldResume: true))
        XCTAssertEqual(model.player.state, .paused(step: 0, elapsed: 0))
    }

    func testUserResumeDuringInterruptionIsNotDoubledByInterruptionEnd() {
        model.start()
        audio.emit(.interruptionBegan)
        clock.advance(by: 5)
        model.resume()
        clock.advance(by: 2)
        model.pause()
        audio.emit(.interruptionEnded(shouldResume: true))
        XCTAssertEqual(model.player.state, .paused(step: 0, elapsed: 2))
    }

    func testHeadphonesRemovedPausesAndStaysPaused() {
        model.start()
        clock.advance(by: 3)
        audio.emit(.outputLost)
        XCTAssertEqual(model.player.state, .paused(step: 0, elapsed: 3))
        XCTAssertEqual(phaseSignals, [])
        XCTAssertFalse(clock.isTicking)
    }

    func testCurrentGroupFollowsPhasesAndStaysAfterStopLikePwa() {
        XCTAssertFalse(model.isInProgress)
        XCTAssertTrue(model.allowsLeaving)
        model.start()
        XCTAssertFalse(model.allowsLeaving)
        XCTAssertEqual(model.currentGroupPosition, "Grupa 1 z 3")
        XCTAssertEqual(model.currentGroupName, "Grupa 1")
        model.skip()
        XCTAssertEqual(model.currentGroupPosition, "Grupa 1 z 3")
        model.pause()
        model.skip()
        XCTAssertEqual(model.currentGroupPosition, "Grupa 2 z 3")
        XCTAssertEqual(model.currentPhaseName, "Napinanie 2")
        XCTAssertEqual(model.player.state, .running(step: 2, startedAt: at(0)))
        XCTAssertTrue(model.isInProgress)
        model.stop()
        XCTAssertFalse(model.isInProgress)
        XCTAssertEqual(model.currentGroupPosition, "Grupa 2 z 3")
        XCTAssertEqual(model.currentGroupName, "Grupa 2")
        XCTAssertEqual(model.shownPhaseName, "Napinanie 2")
        XCTAssertFalse(model.allowsLeaving)
        XCTAssertNil(model.currentFigureName)
    }

    func testNaturalEndAddsCompletedRecordThatSurvivesRestart() {
        clock.advance(by: 3)
        model.start()
        for _ in 0..<200 { clock.advance(by: 1) }
        let expected = SessionRecord(setName: "Test", startedAt: at(3), endedAt: at(183), completed: true, phasesDone: 6, phasesTotal: 6)
        XCTAssertEqual(history.records, [expected])
        XCTAssertEqual(SessionHistory(storage: storage).records, [expected])
    }

    func testStopAddsInterruptedRecordOnceWithPhasesDone() {
        model.start()
        model.skip()
        clock.advance(by: 20)
        model.stop()
        model.stop()
        XCTAssertEqual(history.records, [
            SessionRecord(setName: "Test", startedAt: t0, endedAt: at(20), completed: false, phasesDone: 1, phasesTotal: 6),
        ])
    }

    func testLeavingWithoutStartAddsNoRecord() {
        model.stop()
        XCTAssertEqual(history.records, [])
        XCTAssertNil(storage.data)
    }

    func testUnreadableHistoryFileIsNeverOverwritten() throws {
        let unreadable = Data("nie json".utf8)
        try storage.save(unreadable)
        let history = SessionHistory(storage: storage)
        history.append(SessionRecord(setName: "Test", startedAt: t0, endedAt: at(1), completed: true, phasesDone: 6, phasesTotal: 6))
        XCTAssertEqual(storage.data, unreadable)
        XCTAssertEqual(history.records.count, 1)
    }
}
