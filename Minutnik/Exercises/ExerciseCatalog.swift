import Foundation

struct ExerciseCatalog: Decodable, Equatable {
    static let supportedVersion = 1

    let version: Int
    let sets: [ExerciseSet]

    enum CodingKeys: String, CodingKey {
        case version = "wersja"
        case sets = "zestawy"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        guard version == Self.supportedVersion else {
            throw ExerciseCatalogError.unsupportedVersion(version)
        }
        sets = try container.decode([ExerciseSet].self, forKey: .sets)
    }

    static func decode(_ data: Data) throws -> ExerciseCatalog {
        do {
            return try JSONDecoder().decode(ExerciseCatalog.self, from: data)
        } catch let error as ExerciseCatalogError {
            throw error
        } catch let error as DecodingError {
            throw ExerciseCatalogError.malformed(error.readablePlace)
        } catch {
            throw ExerciseCatalogError.malformed(error.localizedDescription)
        }
    }

    static func bundled(in bundle: Bundle = .main) throws -> ExerciseCatalog {
        guard let url = bundle.url(forResource: "zestawy", withExtension: "json") else {
            throw ExerciseCatalogError.missingFile
        }
        return try decode(Data(contentsOf: url))
    }
}

struct ExerciseSet: Decodable, Equatable {
    let name: String
    let groups: [ExerciseGroup]

    enum CodingKeys: String, CodingKey {
        case name = "nazwa"
        case groups = "grupy"
    }
}

struct ExerciseGroup: Decodable, Equatable {
    let name: String
    let phases: [ExercisePhase]

    var isMuscleGroup: Bool { phases.contains { PhaseKind(phaseName: $0.name) == .tension } }

    enum CodingKeys: String, CodingKey {
        case name = "nazwa"
        case phases = "fazy"
    }
}

struct ExercisePhase: Decodable, Equatable {
    let name: String
    let durationSeconds: Int
    let instructions: PhaseInstructions?

    enum CodingKeys: String, CodingKey {
        case name = "nazwa"
        case durationSeconds = "czasS"
        case instructions = "instrukcje"
    }
}

struct PhaseInstructions: Decodable, Equatable {
    let how: String?
    let tense: String?
    let caution: String?
    let release: String?
    let feel: String?

    enum CodingKeys: String, CodingKey {
        case how = "jak"
        case tense = "napnij"
        case caution = "uwaga"
        case release = "pusc"
        case feel = "poczuj"
    }
}

enum ExerciseCatalogError: Error, Equatable, LocalizedError {
    case missingFile
    case unsupportedVersion(Int)
    case malformed(String)

    var errorDescription: String? {
        switch self {
        case .missingFile: "Brak pliku zestawy.json w apce."
        case .unsupportedVersion(let version): "Nieznana wersja formatu zestawów: \(version) (obsługiwana: \(ExerciseCatalog.supportedVersion))."
        case .malformed(let detail): "Błędny plik zestawów: \(detail)"
        }
    }
}

private extension DecodingError {
    var readablePlace: String {
        switch self {
        case .keyNotFound(let key, let context): "brak pola „\(key.stringValue)” w \(context.codingPath.readablePath)"
        case .typeMismatch(_, let context), .valueNotFound(_, let context): "zły typ pola \(context.codingPath.readablePath)"
        case .dataCorrupted(let context): "to nie jest poprawny JSON (\(context.codingPath.readablePath))"
        @unknown default: localizedDescription
        }
    }
}

private extension Array where Element == CodingKey {
    var readablePath: String {
        let path = map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
        return path.isEmpty ? "korzeniu" : String(path.drop { $0 == "." })
    }
}
