import Foundation

struct ReadingText: Decodable, Equatable {
    let title: String
    let sections: [ReadingSection]
    let source: String

    enum CodingKeys: String, CodingKey {
        case title = "tytul"
        case sections = "sekcje"
        case source = "zrodlo"
    }

    static let fileName = "o-cwiczeniu"

    static func decode(_ data: Data) throws -> ReadingText {
        let text: ReadingText
        do {
            text = try JSONDecoder().decode(ReadingText.self, from: data)
        } catch {
            throw ReadingTextError.malformed
        }
        guard !text.sections.isEmpty, text.sections.allSatisfy(\.isWellFormed) else { throw ReadingTextError.malformed }
        return text
    }

    static func bundled(in bundle: Bundle = .main) throws -> ReadingText {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else { throw ReadingTextError.missingFile }
        return try decode(Data(contentsOf: url))
    }
}

struct ReadingSection: Decodable, Equatable {
    let heading: String
    let paragraphs: [String]
    let points: [String]

    var hasContent: Bool { !paragraphs.isEmpty || !points.isEmpty }
    var isWellFormed: Bool { hasContent && ([heading] + paragraphs + points).allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }

    enum CodingKeys: String, CodingKey {
        case heading = "naglowek"
        case paragraphs = "akapity"
        case points = "punkty"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        heading = try container.decode(String.self, forKey: .heading)
        paragraphs = try container.decodeIfPresent([String].self, forKey: .paragraphs) ?? []
        points = try container.decodeIfPresent([String].self, forKey: .points) ?? []
    }
}

enum ReadingTextError: Error, Equatable, LocalizedError {
    case missingFile
    case malformed

    var errorDescription: String? {
        switch self {
        case .missingFile: "Brak tekstu „O ćwiczeniu” w apce."
        case .malformed: "Błędny tekst „O ćwiczeniu”."
        }
    }
}
