import XCTest
@testable import Minutnik

final class ExerciseCatalogTests: XCTestCase {
    func testBundledCatalogHasPrmSetsWithTwelveAndEightGroups() throws {
        let catalog = try ExerciseCatalog.bundled()
        XCTAssertEqual(catalog.sets.map(\.name), ["12 grup", "8 grup"])
        XCTAssertEqual(catalog.sets.map(\.groups.count), [12, 8])
    }

    func testEveryBundledGroupTensesTenAndRelaxesFiftySeconds() throws {
        let catalog = try ExerciseCatalog.bundled()
        let phases = catalog.sets.flatMap(\.groups).map { $0.phases.map(\.durationSeconds) }
        XCTAssertEqual(Set(phases), [[10, 50]])
    }

    func testBundledPhasesCarryPrmInstructions() throws {
        let catalog = try ExerciseCatalog.bundled()
        let first = try XCTUnwrap(catalog.sets.first?.groups.first)
        XCTAssertEqual(first.name, "Przedramiona")
        XCTAssertFalse(try XCTUnwrap(first.phases[0].instructions?.how).isEmpty)
        XCTAssertNotNil(first.phases[1].instructions?.feel)
        XCTAssertNil(first.phases[1].instructions?.tense)
    }

    func testUnknownVersionGivesReadableError() {
        let data = Data(#"{"wersja": 2, "zestawy": []}"#.utf8)
        XCTAssertThrowsError(try ExerciseCatalog.decode(data)) { error in
            XCTAssertEqual(error as? ExerciseCatalogError, .unsupportedVersion(2))
            XCTAssertEqual(error.localizedDescription, "Nieznana wersja formatu zestawów: 2 (obsługiwana: 1).")
        }
    }

    func testMalformedFileGivesReadableError() {
        let data = Data(#"{"wersja": 1, "zestawy": [{"nazwa": "X"}]}"#.utf8)
        XCTAssertThrowsError(try ExerciseCatalog.decode(data)) { error in
            XCTAssertEqual(error.localizedDescription, "Błędny plik zestawów: brak pola „grupy” w zestawy[0]")
        }
    }

    func testPhaseWithoutInstructionsDecodes() throws {
        let data = Data(#"{"wersja": 1, "zestawy": [{"nazwa": "S", "grupy": [{"nazwa": "G", "fazy": [{"nazwa": "Wdech", "czasS": 4}]}]}]}"#.utf8)
        let phase = try XCTUnwrap(ExerciseCatalog.decode(data).sets.first?.groups.first?.phases.first)
        XCTAssertEqual(phase, ExercisePhase(name: "Wdech", durationSeconds: 4, instructions: nil))
    }
}
