import SwiftUI
import os

enum Log {
    private static let subsystem = "com.md4ps.minutnik"
    static let navigation = Logger(subsystem: subsystem, category: "navigation")
    static let session = Logger(subsystem: subsystem, category: "session")
    static let sound = Logger(subsystem: subsystem, category: "sound")
}

extension View {
    func loggedScreen(_ name: String) -> some View {
        onAppear { Log.navigation.notice("ekran pokazany: \(name, privacy: .public)") }
            .onDisappear { Log.navigation.notice("ekran zniknął: \(name, privacy: .public)") }
    }
}
