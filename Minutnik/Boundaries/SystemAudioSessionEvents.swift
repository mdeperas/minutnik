import AVFoundation

@MainActor
final class SystemAudioSessionEvents: AudioSessionEvents {
    private var handler: (@MainActor (AudioSessionEvent) -> Void)?
    private var observers: [NSObjectProtocol] = []

    init(center: NotificationCenter = .default) {
        observers = [
            center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
                let event = AudioSessionEventMapping.interruption(note.userInfo ?? [:])
                MainActor.assumeIsolated { self?.deliver(event) }
            },
            center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
                let event = AudioSessionEventMapping.routeChange(note.userInfo ?? [:])
                MainActor.assumeIsolated { self?.deliver(event) }
            },
        ]
    }

    func onEvent(_ handler: @escaping @MainActor (AudioSessionEvent) -> Void) { self.handler = handler }

    private func deliver(_ event: AudioSessionEvent?) {
        guard let event else { return }
        handler?(event)
    }
}

enum AudioSessionEventMapping {
    static func interruption(_ info: [AnyHashable: Any]) -> AudioSessionEvent? {
        guard let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return nil }
        switch type {
        case .began:
            let rawReason = info[AVAudioSessionInterruptionReasonKey] as? UInt
            if rawReason.flatMap(AVAudioSession.InterruptionReason.init) == .appWasSuspended { return nil }
            return .interruptionBegan
        case .ended:
            let options = AVAudioSession.InterruptionOptions(rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
            return .interruptionEnded(shouldResume: options.contains(.shouldResume))
        @unknown default:
            return nil
        }
    }

    static func routeChange(_ info: [AnyHashable: Any]) -> AudioSessionEvent? {
        guard let rawReason = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable else { return nil }
        return .outputLost
    }
}
