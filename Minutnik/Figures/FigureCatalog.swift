import UIKit

struct FigureCatalog: Equatable {
    private let assets: [String: [String: String]]

    init(json: Data) throws {
        assets = try JSONDecoder().decode([String: [String: String]].self, from: json)
    }

    static func bundled() -> FigureCatalog? {
        guard let data = NSDataAsset(name: "mapa-rycin")?.data else { return nil }
        return try? FigureCatalog(json: data)
    }

    func assetName(group: String, kind: PhaseKind) -> String? {
        let state = switch kind {
        case .tension: "napiecie"
        case .relaxation: "rozluznienie"
        }
        return assets[group]?[state].map { ($0 as NSString).deletingPathExtension }
    }
}
