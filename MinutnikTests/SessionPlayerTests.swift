import XCTest
@testable import Minutnik

final class SessionPlayerTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 1_000)

    private func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    private func prm(groups: Int = 3) -> SessionPlayer {
        SessionPlayer(steps: (0..<groups).flatMap { group in
            [PlayerStep(groupIndex: group, phaseIndex: 0, duration: 10), PlayerStep(groupIndex: group, phaseIndex: 1, duration: 50)]
        })
    }

    private func started(groups: Int = 3) -> SessionPlayer {
        var player = prm(groups: groups)
        _ = player.start(now: at(0))
        return player
    }

    func testBuildsStepsFromSetInOrder() throws {
        let set = try XCTUnwrap(ExerciseCatalog.bundled().sets.first)
        let player = SessionPlayer(set: set)
        XCTAssertEqual(player.steps.count, 24)
        XCTAssertEqual(player.steps[1], PlayerStep(groupIndex: 0, phaseIndex: 1, duration: 50))
        XCTAssertEqual(player.steps[2], PlayerStep(groupIndex: 1, phaseIndex: 0, duration: 10))
    }

    func testReadyStartsFirstPhase() {
        var player = prm()
        XCTAssertEqual(player.state, .ready)
        XCTAssertEqual(player.remainingInSession(now: at(0)), 180)
        XCTAssertEqual(player.start(now: at(0)), [.phaseStarted(step: 0, at: at(0))])
        XCTAssertEqual(player.state, .running(step: 0, startedAt: at(0)))
    }

    func testStartWhenNotReadyDoesNothing() {
        var player = started()
        XCTAssertEqual(player.start(now: at(5)), [])
        XCTAssertEqual(player.state, .running(step: 0, startedAt: at(0)))
    }

    func testEmptySessionFinishesAtStart() {
        var player = SessionPlayer(steps: [])
        XCTAssertEqual(player.start(now: at(0)), [.sessionFinished(at: at(0))])
        XCTAssertEqual(player.state, .finished)
    }

    func testTickBeforePhaseEndChangesNothing() {
        var player = started()
        XCTAssertEqual(player.tick(now: at(9.9)), [])
        XCTAssertEqual(player.remainingInPhase(now: at(9.9)), 0.1, accuracy: 0.0001)
    }

    func testPhaseEndStartsNextPhaseExactlyAtEnd() {
        var player = started()
        XCTAssertEqual(player.tick(now: at(10.4)), [.phaseStarted(step: 1, at: at(10))])
        XCTAssertEqual(player.state, .running(step: 1, startedAt: at(10)))
    }

    func testLastPhaseEndFinishesSession() {
        var player = started(groups: 1)
        XCTAssertEqual(player.tick(now: at(60)), [.phaseStarted(step: 1, at: at(10)), .sessionFinished(at: at(60))])
        XCTAssertEqual(player.state, .finished)
        XCTAssertEqual(player.remainingInSession(now: at(60)), 0)
    }

    func testWakingAfterThreeMinutesCatchesUpThroughManyPhases() {
        var player = started(groups: 4)
        let events = player.tick(now: at(185))
        XCTAssertEqual(events, [
            .phaseStarted(step: 1, at: at(10)),
            .phaseStarted(step: 2, at: at(60)),
            .phaseStarted(step: 3, at: at(70)),
            .phaseStarted(step: 4, at: at(120)),
            .phaseStarted(step: 5, at: at(130)),
            .phaseStarted(step: 6, at: at(180)),
        ])
        XCTAssertEqual(player.state, .running(step: 6, startedAt: at(180)))
        XCTAssertEqual(player.remainingInSession(now: at(185)), 55)
    }

    func testWakingAfterSessionEndFinishesAtScheduledTime() {
        var player = started(groups: 2)
        let events = player.tick(now: at(500))
        XCTAssertEqual(events.last, .sessionFinished(at: at(120)))
        XCTAssertEqual(player.state, .finished)
    }

    func testPauseFreezesRemainingTime() {
        var player = started()
        XCTAssertEqual(player.pause(now: at(4)), [])
        XCTAssertEqual(player.state, .paused(step: 0, elapsed: 4))
        XCTAssertEqual(player.tick(now: at(400)), [])
        XCTAssertEqual(player.remainingInPhase(now: at(400)), 6)
        XCTAssertEqual(player.remainingInSession(now: at(400)), 176)
        XCTAssertEqual(player.upcomingPhaseEnds(), [])
    }

    func testPauseAfterMissedPhaseEndCatchesUpFirst() {
        var player = started()
        XCTAssertEqual(player.pause(now: at(12)), [.phaseStarted(step: 1, at: at(10))])
        XCTAssertEqual(player.state, .paused(step: 1, elapsed: 2))
    }

    func testResumeContinuesWithoutDrift() {
        var player = started()
        _ = player.pause(now: at(4))
        XCTAssertEqual(player.resume(now: at(100)), [])
        XCTAssertEqual(player.state, .running(step: 0, startedAt: at(96)))
        XCTAssertEqual(player.tick(now: at(105.9)), [])
        XCTAssertEqual(player.tick(now: at(106)), [.phaseStarted(step: 1, at: at(106))])
    }

    func testRepeatedPauseResumeDoesNotDrift() {
        var player = started(groups: 1)
        var now: TimeInterval = 0
        for _ in 0..<20 {
            now += 1.3
            _ = player.pause(now: at(now))
            now += 7.7
            _ = player.resume(now: at(now))
        }
        XCTAssertEqual(player.remainingInSession(now: at(now)), 60 - 26, accuracy: 0.0001)
    }

    func testResumeWhenRunningDoesNothing() {
        var player = started()
        XCTAssertEqual(player.resume(now: at(3)), [])
        XCTAssertEqual(player.state, .running(step: 0, startedAt: at(0)))
    }

    func testSkipStartsNextPhaseNow() {
        var player = started()
        XCTAssertEqual(player.skip(now: at(3)), [.phaseStarted(step: 1, at: at(3))])
        XCTAssertEqual(player.state, .running(step: 1, startedAt: at(3)))
    }

    func testSkipWhilePausedRunsNextPhase() {
        var player = started()
        _ = player.pause(now: at(3))
        XCTAssertEqual(player.skip(now: at(30)), [.phaseStarted(step: 1, at: at(30))])
        XCTAssertEqual(player.state, .running(step: 1, startedAt: at(30)))
    }

    func testSkipLastPhaseFinishesSession() {
        var player = started(groups: 1)
        _ = player.skip(now: at(1))
        XCTAssertEqual(player.skip(now: at(2)), [.sessionFinished(at: at(2))])
        XCTAssertEqual(player.state, .finished)
    }

    func testStopEndsSessionWithoutFinish() {
        var player = started()
        XCTAssertEqual(player.stop(now: at(5)), [.sessionStopped(at: at(5))])
        XCTAssertEqual(player.state, .stopped)
        XCTAssertEqual(player.skip(now: at(6)), [])
        XCTAssertEqual(player.resume(now: at(6)), [])
        XCTAssertEqual(player.remainingInSession(now: at(6)), 0)
    }

    func testStopWhilePaused() {
        var player = started()
        _ = player.pause(now: at(5))
        XCTAssertEqual(player.stop(now: at(9)), [.sessionStopped(at: at(9))])
    }

    func testStopInReadyDoesNothing() {
        var player = prm()
        XCTAssertEqual(player.stop(now: at(0)), [])
        XCTAssertEqual(player.state, .ready)
    }

    func testUpcomingPhaseEndsListWholeRestOfSession() {
        var player = started(groups: 2)
        _ = player.tick(now: at(15))
        XCTAssertEqual(player.upcomingPhaseEnds(), [
            PhaseEnd(step: 1, at: at(60)),
            PhaseEnd(step: 2, at: at(70)),
            PhaseEnd(step: 3, at: at(120)),
        ])
    }

    func testUpcomingPhaseEndsShiftAfterPause() {
        var player = started(groups: 1)
        _ = player.pause(now: at(5))
        _ = player.resume(now: at(25))
        XCTAssertEqual(player.upcomingPhaseEnds().map(\.at), [at(30), at(80)])
    }

    func testSkipLastPhaseWhilePausedFinishesSession() {
        var player = started(groups: 1)
        _ = player.skip(now: at(1))
        _ = player.pause(now: at(2))
        XCTAssertEqual(player.skip(now: at(9)), [.sessionFinished(at: at(9))])
        XCTAssertEqual(player.state, .finished)
    }

    func testSkipAfterLongBackgroundSkipsPhaseWhereNowFalls() {
        var player = started()
        XCTAssertEqual(player.skip(now: at(65)), [
            .phaseStarted(step: 1, at: at(10)),
            .phaseStarted(step: 2, at: at(60)),
            .phaseStarted(step: 3, at: at(65)),
        ])
    }

    func testFinishedIgnoresEveryAction() {
        var player = started(groups: 1)
        _ = player.tick(now: at(60))
        let before = player
        XCTAssertEqual(player.pause(now: at(61)) + player.resume(now: at(61)) + player.skip(now: at(61)) + player.stop(now: at(61)) + player.tick(now: at(61)), [])
        XCTAssertEqual(player, before)
    }

    func testPauseWithClockBeforePhaseStartKeepsFullPhase() {
        var player = started()
        _ = player.pause(now: at(-3))
        XCTAssertEqual(player.state, .paused(step: 0, elapsed: 0))
        XCTAssertEqual(player.remainingInPhase(now: at(-3)), 10)
    }
}
