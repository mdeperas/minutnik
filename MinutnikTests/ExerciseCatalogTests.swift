import XCTest
@testable import Minutnik

final class ExerciseCatalogTests: XCTestCase {
    func testBundledCatalogHasOnePrmSetWithIntroTwelveGroupsRelaxAndReturn() throws {
        let catalog = try ExerciseCatalog.bundled()
        XCTAssertEqual(catalog.sets.map(\.name), ["12 grup"])
        let groups = try XCTUnwrap(catalog.sets.first).groups
        XCTAssertEqual(groups.count, 15)
        XCTAssertEqual(groups.filter(\.isMuscleGroup).count, 12)
        XCTAssertEqual(groups.first?.phases.map(\.name), ["Wstęp"])
        XCTAssertEqual(groups.suffix(2).map { $0.phases.map(\.name) }, [["Relaks"], ["Powrót"]])
    }

    func testBundledTimesAreIntroThirtyGroupsTenAndFiftyRelaxTwoMinutesReturnThirty() throws {
        let groups = try XCTUnwrap(ExerciseCatalog.bundled().sets.first).groups
        let times = groups.map { $0.phases.map(\.durationSeconds) }
        XCTAssertEqual(times.first, [30])
        XCTAssertEqual(Set(times.dropFirst().dropLast(2)), [[10, 50]])
        XCTAssertEqual(Array(times.suffix(2)), [[120], [30]])
    }

    func testBundledPhasesCarryPrmInstructions() throws {
        let groups = try XCTUnwrap(ExerciseCatalog.bundled().sets.first).groups
        XCTAssertFalse(try XCTUnwrap(groups[0].phases[0].instructions?.how).isEmpty)
        let first = groups[1]
        XCTAssertEqual(first.name, "Przedramiona")
        XCTAssertFalse(try XCTUnwrap(first.phases[0].instructions?.how).isEmpty)
        XCTAssertNotNil(first.phases[1].instructions?.feel)
        XCTAssertNil(first.phases[1].instructions?.tense)
        XCTAssertFalse(try XCTUnwrap(groups[14].phases[0].instructions?.how).isEmpty)
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
