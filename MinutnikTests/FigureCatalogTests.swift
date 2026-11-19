import XCTest
@testable import Minutnik

final class FigureCatalogTests: XCTestCase {
    private let catalog = try! FigureCatalog(json: Data(#"{"Dłonie": {"napiecie": "dlonie-n.svg", "rozluznienie": "dlonie-r.svg"}}"#.utf8))

    func testTensionPicksTensedFigure() {
        XCTAssertEqual(catalog.assetName(group: "Dłonie", kind: .tension), "dlonie-n")
    }

    func testRelaxationPicksRelaxedFigure() {
        XCTAssertEqual(catalog.assetName(group: "Dłonie", kind: .relaxation), "dlonie-r")
    }

    func testGroupWithoutFigureHasNone() {
        XCTAssertNil(catalog.assetName(group: "Stopy", kind: .tension))
    }

    func testAppBundlesFigureMap() {
        XCTAssertNotNil(FigureCatalog.bundled())
    }
}
