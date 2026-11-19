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

    static func groupPosition(_ index: Int, of count: Int) -> String { "Grupa \(index + 1) z \(count)" }

    static func summary(of set: ExerciseSet) -> String {
        "\(groupCount(set.groups.count)) · \(minutes(of: set))"
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
