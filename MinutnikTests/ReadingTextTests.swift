import XCTest
@testable import Minutnik

final class ReadingTextTests: XCTestCase {
    func testBundledTextHasSectionsWithContentAndBookSource() throws {
        let text = try ReadingText.bundled()
        XCTAssertEqual(text.title, "O ćwiczeniu")
        XCTAssertGreaterThanOrEqual(text.sections.count, 5)
        XCTAssertTrue(text.sections.allSatisfy(\.hasContent))
        XCTAssertTrue(text.source.contains("Ponad lękiem"))
    }

    func testMissingParagraphsOrPointsAreEmpty() throws {
        let data = Data(#"{"tytul": "T", "zrodlo": "Z", "sekcje": [{"naglowek": "N", "punkty": ["p"]}]}"#.utf8)
        let section = try XCTUnwrap(ReadingText.decode(data).sections.first)
        XCTAssertEqual(section.paragraphs, [])
        XCTAssertEqual(section.points, ["p"])
    }

    func testSectionWithoutContentOrNoSectionsIsMalformed() {
        for json in [#"{"tytul": "T", "zrodlo": "Z", "sekcje": []}"#, #"{"tytul": "T", "zrodlo": "Z", "sekcje": [{"naglowek": "N"}]}"#, #"{"tytul": "T", "zrodlo": "Z", "sekcje": [{"naglowek": " ", "akapity": ["a"]}]}"#, #"{"tytul": "T"}"#] {
            XCTAssertThrowsError(try ReadingText.decode(Data(json.utf8))) { error in
                XCTAssertEqual(error as? ReadingTextError, .malformed)
                XCTAssertEqual(error.localizedDescription, "Błędny tekst „O ćwiczeniu”.")
            }
        }
    }
}
