import Foundation

@MainActor
final class SystemClock: SessionClock {
    private let tickInterval: TimeInterval
    private var timer: Timer?

    init(tickInterval: TimeInterval = 0.25) {
        self.tickInterval = tickInterval
    }

    var now: Date { Date() }

    func startTicking(_ onTick: @escaping @MainActor () -> Void) {
        stopTicking()
        let timer = Timer(timeInterval: tickInterval, repeats: true) { _ in
            MainActor.assumeIsolated { onTick() }
        }
        timer.tolerance = tickInterval / 5
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stopTicking() {
        timer?.invalidate()
        timer = nil
    }
}
