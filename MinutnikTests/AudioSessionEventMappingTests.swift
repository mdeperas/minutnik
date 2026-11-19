import AVFoundation
import XCTest
@testable import Minutnik

final class AudioSessionEventMappingTests: XCTestCase {
    private let began = AVAudioSession.InterruptionType.began.rawValue
    private let ended = AVAudioSession.InterruptionType.ended.rawValue

    func testInterruptionBeganPauses() {
        XCTAssertEqual(AudioSessionEventMapping.interruption([AVAudioSessionInterruptionTypeKey: began]), .interruptionBegan)
    }

    func testInterruptionFromAppSuspensionIsIgnored() {
        let info: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: began,
            AVAudioSessionInterruptionReasonKey: AVAudioSession.InterruptionReason.appWasSuspended.rawValue,
        ]
        XCTAssertNil(AudioSessionEventMapping.interruption(info))
    }

    func testInterruptionEndedCarriesShouldResume() {
        let resume: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: ended,
            AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue,
        ]
        XCTAssertEqual(AudioSessionEventMapping.interruption(resume), .interruptionEnded(shouldResume: true))
        XCTAssertEqual(AudioSessionEventMapping.interruption([AVAudioSessionInterruptionTypeKey: ended]), .interruptionEnded(shouldResume: false))
    }

    func testOnlyLostOutputDeviceCountsAsRouteLoss() {
        let lost = AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
        let added = AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
        XCTAssertEqual(AudioSessionEventMapping.routeChange([AVAudioSessionRouteChangeReasonKey: lost]), .outputLost)
        XCTAssertNil(AudioSessionEventMapping.routeChange([AVAudioSessionRouteChangeReasonKey: added]))
    }
}
