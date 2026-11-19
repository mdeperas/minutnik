import Foundation

struct BoxBreath: Equatable {
    enum Stage: Equatable, CaseIterable {
        case inhale, holdFull, exhale, holdEmpty

        var label: String {
            switch self {
            case .inhale: "Wdech"
            case .exhale: "Wydech"
            case .holdFull, .holdEmpty: "Trzymaj"
            }
        }
    }

    static let stageDuration: TimeInterval = 4

    let stage: Stage
    let secondsLeft: Int
    let index: Int
    let stageProgress: Double
    let cycleProgress: Double

    init(elapsed: TimeInterval) {
        let time = max(0, elapsed)
        index = Int((time / Self.stageDuration).rounded(.down))
        let inStage = time - Double(index) * Self.stageDuration
        let stages = Stage.allCases
        stage = stages[index % stages.count]
        secondsLeft = Int(Self.stageDuration) - Int(inStage.rounded(.down))
        stageProgress = inStage / Self.stageDuration
        cycleProgress = (Double(index % stages.count) + stageProgress) / Double(stages.count)
    }

    var fullness: Double {
        switch stage {
        case .inhale: stageProgress
        case .holdFull: 1
        case .exhale: 1 - stageProgress
        case .holdEmpty: 0
        }
    }
}

struct HapticBeat: Equatable {
    let step: Int
    let mark: Int

    static let countdownSeconds: TimeInterval = 3

    static func at(step: Int, kind: PhaseKind, remaining: TimeInterval, duration: TimeInterval) -> HapticBeat? {
        guard remaining > 0 else { return nil }
        if remaining <= countdownSeconds { return HapticBeat(step: step, mark: -Int(remaining.rounded(.up))) }
        guard kind == .relaxation else { return HapticBeat(step: step, mark: 0) }
        return HapticBeat(step: step, mark: BoxBreath(elapsed: duration - remaining).index)
    }

    static func cue(from old: HapticBeat?, to new: HapticBeat?) -> HapticCue? {
        guard let new else { return nil }
        guard let old, old.step == new.step else { return .phaseStarted }
        guard old.mark != new.mark else { return nil }
        return new.mark < 0 ? .countdown : .breath
    }
}
