import SwiftUI

@main
struct MinutnikApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let environment = AppEnvironment.current

    var body: some Scene {
        WindowGroup {
            StartView(environment: environment)
                .preferredColorScheme(.dark)
                .tint(Color(PhaseKind.tension.ringColor))
                .onChange(of: scenePhase) { _, phase in
                    Log.navigation.notice("scenePhase: \(String(describing: phase), privacy: .public)")
                }
        }
    }
}
