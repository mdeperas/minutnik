import UserNotifications

@MainActor
final class LocalPhaseNotifier: PhaseNotifier {
    static let limit = 64
    private static let idPrefix = "faza-"

    private let center: UNUserNotificationCenter
    private var generation = 0

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async {
        guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
        let granted = (try? await center.requestAuthorization(options: [.alert])) ?? false
        Log.session.notice("zgoda na powiadomienia: \(granted, privacy: .public)")
    }

    func replace(with alerts: [PhaseAlert]) {
        cancelAll()
        let current = generation
        Task {
            guard await isAuthorized(), current == generation else { return }
            for (index, alert) in alerts.prefix(Self.limit).enumerated() where current == generation {
                await add(alert, id: Self.id(index))
                if current != generation { center.removePendingNotificationRequests(withIdentifiers: [Self.id(index)]) }
            }
        }
    }

    func cancelAll() {
        generation += 1
        center.removePendingNotificationRequests(withIdentifiers: (0..<Self.limit).map(Self.id))
    }

    private static func id(_ index: Int) -> String { "\(idPrefix)\(index)" }

    private func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    private func add(_ alert: PhaseAlert, id: String) async {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: alert.at)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        do {
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } catch {
            Log.session.error("powiadomienie nie weszło: \(error.localizedDescription, privacy: .public)")
        }
    }
}
