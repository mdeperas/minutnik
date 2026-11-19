import Foundation

struct AppVersion {
    let label: String

    init(info: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        let commit = info["MinutnikGitCommit"] as? String ?? "?"
        let released = info["MinutnikReleaseDate"] as? String ?? "?"
        label = "Wersja \(version) (\(build)) · \(commit) · \(released)"
    }
}
