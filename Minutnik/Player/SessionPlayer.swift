import Foundation

struct PlayerStep: Equatable {
    let groupIndex: Int
    let phaseIndex: Int
    let duration: TimeInterval
}

enum PlayerState: Equatable {
    case ready
    case running(step: Int, startedAt: Date)
    case paused(step: Int, elapsed: TimeInterval)
    case finished
    case stopped
}

enum PlayerEvent: Equatable {
    case phaseStarted(step: Int, at: Date)
    case sessionFinished(at: Date)
    case sessionStopped(at: Date)
}

struct PhaseEnd: Equatable {
    let step: Int
    let at: Date
}

struct SessionPlayer: Equatable {
    let steps: [PlayerStep]
    private(set) var state: PlayerState = .ready

    init(steps: [PlayerStep]) {
        self.steps = steps
    }

    init(set: ExerciseSet) {
        self.init(steps: set.groups.enumerated().flatMap { groupIndex, group in
            group.phases.enumerated().map { phaseIndex, phase in
                PlayerStep(groupIndex: groupIndex, phaseIndex: phaseIndex, duration: TimeInterval(phase.durationSeconds))
            }
        })
    }

    mutating func start(now: Date) -> [PlayerEvent] {
        guard state == .ready else { return [] }
        return enter(step: 0, plannedStart: now, now: now)
    }

    mutating func pause(now: Date) -> [PlayerEvent] {
        let events = tick(now: now)
        guard case .running(let step, let startedAt) = state else { return events }
        state = .paused(step: step, elapsed: max(0, now.timeIntervalSince(startedAt)))
        return events
    }

    mutating func resume(now: Date) -> [PlayerEvent] {
        guard case .paused(let step, let elapsed) = state else { return [] }
        state = .running(step: step, startedAt: now.addingTimeInterval(-elapsed))
        return []
    }

    mutating func skip(now: Date) -> [PlayerEvent] {
        let events = tick(now: now)
        switch state {
        case .running(let step, _), .paused(let step, _):
            return events + enter(step: step + 1, plannedStart: now, now: now)
        default:
            return events
        }
    }

    mutating func stop(now: Date) -> [PlayerEvent] {
        let events = tick(now: now)
        switch state {
        case .running, .paused:
            state = .stopped
            return events + [.sessionStopped(at: now)]
        default:
            return events
        }
    }

    mutating func tick(now: Date) -> [PlayerEvent] {
        guard case .running(let step, let startedAt) = state else { return [] }
        let end = startedAt.addingTimeInterval(steps[step].duration)
        guard now >= end else { return [] }
        return enter(step: step + 1, plannedStart: end, now: now)
    }

    func remainingInPhase(now: Date) -> TimeInterval {
        switch state {
        case .running(let step, let startedAt):
            max(0, steps[step].duration - now.timeIntervalSince(startedAt))
        case .paused(let step, let elapsed):
            max(0, steps[step].duration - elapsed)
        case .ready, .finished, .stopped:
            0
        }
    }

    func remainingInSession(now: Date) -> TimeInterval {
        switch state {
        case .ready:
            durationOfSteps(from: 0)
        case .running(let step, _), .paused(let step, _):
            remainingInPhase(now: now) + durationOfSteps(from: step + 1)
        case .finished, .stopped:
            0
        }
    }

    func upcomingPhaseEnds() -> [PhaseEnd] {
        guard case .running(let step, let startedAt) = state else { return [] }
        var at = startedAt
        return (step..<steps.count).map { index in
            at = at.addingTimeInterval(steps[index].duration)
            return PhaseEnd(step: index, at: at)
        }
    }

    private func durationOfSteps(from first: Int) -> TimeInterval {
        steps.dropFirst(first).reduce(0) { $0 + $1.duration }
    }

    private mutating func enter(step first: Int, plannedStart: Date, now: Date) -> [PlayerEvent] {
        var events: [PlayerEvent] = []
        var step = first
        var startedAt = plannedStart
        while step < steps.count {
            events.append(.phaseStarted(step: step, at: startedAt))
            let end = startedAt.addingTimeInterval(steps[step].duration)
            guard now >= end else {
                state = .running(step: step, startedAt: startedAt)
                return events
            }
            step += 1
            startedAt = end
        }
        state = .finished
        return events + [.sessionFinished(at: startedAt)]
    }
}
