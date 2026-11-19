import Foundation

struct PhaseLine: Equatable {
    let label: String
    let text: String
}

enum PhaseText {
    static func lines(_ instructions: PhaseInstructions?) -> [PhaseLine] {
        guard let instructions else { return [] }
        let candidates: [(String, String?)] = [
            ("Jak", instructions.how),
            ("Napnij", instructions.tense),
            ("Uwaga", instructions.caution),
            ("Puść", instructions.release),
            ("Poczuj", instructions.feel),
        ]
        return candidates.compactMap { label, text in
            guard let text, !text.isEmpty else { return nil }
            return PhaseLine(label: label, text: text)
        }
    }

    static func groupPosition(_ index: Int, in set: ExerciseSet) -> String? {
        guard set.groups[index].isMuscleGroup else { return nil }
        let muscleGroups = set.groups.filter(\.isMuscleGroup).count
        let number = set.groups[...index].filter(\.isMuscleGroup).count
        return "Grupa \(number) z \(muscleGroups)"
    }

    static func summary(of set: ExerciseSet) -> String {
        "\(groupCount(set.groups.filter(\.isMuscleGroup).count)) · \(minutes(of: set))"
    }

    static func minutes(of set: ExerciseSet) -> String {
        let seconds = set.groups.flatMap(\.phases).reduce(0) { $0 + $1.durationSeconds }
        return "\(Int((Double(seconds) / 60).rounded(.up))) min"
    }

    static func groupCount(_ count: Int) -> String {
        let tens = count % 100
        let word = count == 1 ? "grupa" : (2...4).contains(count % 10) && !(12...14).contains(tens) ? "grupy" : "grup"
        return "\(count) \(word)"
    }
}
