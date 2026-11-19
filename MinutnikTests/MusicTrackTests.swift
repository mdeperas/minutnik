import XCTest
@testable import Minutnik

final class MusicTrackTests: XCTestCase {
    func testStoredChoiceComesBackAndUnknownMeansNoMusic() {
        XCTAssertEqual(MusicTrack(stored: "kosmos"), .cosmos)
        XCTAssertEqual(MusicTrack(stored: "synthwave"), .synthwave)
        XCTAssertEqual(MusicTrack(stored: nil), MusicTrack.none)
        XCTAssertEqual(MusicTrack(stored: "disco"), MusicTrack.none)
        XCTAssertEqual(MusicTrack.cosmos.fileName, "kosmos")
        XCTAssertNil(MusicTrack.none.fileName)
    }

    func testPlaysOnlyWhileRunningUnmutedAndQuieterThanSignals() {
        let running = PlayerState.running(step: 0, startedAt: Date())
        XCTAssertEqual(MusicTrack.synthwave.volume(muted: false, state: running), MusicTrack.volume)
        XCTAssertLessThan(MusicTrack.volume, 0.5)
        XCTAssertEqual(MusicTrack.synthwave.volume(muted: true, state: running), 0)
        XCTAssertEqual(MusicTrack.none.volume(muted: false, state: running), 0)
        for state in [PlayerState.ready, .paused(step: 0, elapsed: 1), .finished, .stopped] {
            XCTAssertEqual(MusicTrack.cosmos.volume(muted: false, state: state), 0)
        }
    }
}

@MainActor
final class SessionMusicIntegrationTests: XCTestCase {
    func testMusicStartsWithSessionFadesOnPauseAndMuteAndStopsAtEnd() {
        let clock = ManualClock(now: Date(timeIntervalSinceReferenceDate: 0))
        let music = RecordingMusicPlayer()
        let defaults = UserDefaults(suiteName: "minutnik-music-tests")!
        defaults.removePersistentDomain(forName: "minutnik-music-tests")
        let environment = AppEnvironment(version: AppVersion(info: [:]), clock: clock, signals: RecordingSignalPlayer(), notifier: RecordingPhaseNotifier(),
            audioEvents: RecordingAudioEvents(), catalog: .failure(ExerciseCatalogError.missingFile),
            history: SessionHistory(storage: InMemoryHistoryStorage()), haptics: RecordingHapticPlayer(), figures: nil,
            music: music, settings: defaults)
        environment.musicTrack = .cosmos
        let set = ExerciseSet(name: "Test", groups: [ExerciseGroup(name: "G", phases: [ExercisePhase(name: "Napinanie", durationSeconds: 10, instructions: nil)])])
        let model = environment.makeSession(set)
        XCTAssertTrue(model.hasMusic)
        model.start()
        model.pause()
        model.resume()
        model.toggleMusic()
        model.toggleMusic()
        clock.advance(by: 11)
        XCTAssertEqual(music.calls, ["play kosmos", "fade 0.3", "fade 0.0", "fade 0.3", "fade 0.0", "fade 0.3", "stop"])
    }
}
