import Foundation

enum ClockText {
    static func minutesSeconds(_ seconds: TimeInterval) -> String {
        let whole = Int(max(0, seconds).rounded(.up))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}
