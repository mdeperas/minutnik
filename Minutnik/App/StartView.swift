import SwiftUI

struct StartView: View {
    let environment: AppEnvironment
    @State private var session: SessionModel?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Minutnik")
                            .font(.largeTitle.bold())
                            .accessibilityIdentifier("start.title")
                        Text(environment.version.label)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Zestawy") { setRows }
                historySection
            }
            .scrollContentBackground(.hidden)
            .background(Color(PhaseLook.background))
            .navigationDestination(item: $session) { SessionView(model: $0) }
        }
        .task { await environment.notifier.requestAuthorization() }
        .loggedScreen("start")
    }

    @ViewBuilder
    private var historySection: some View {
        let records = environment.history.newestFirst
        if !records.isEmpty {
            Section {
                ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.setName).font(.headline)
                        Text(record.startedAt, format: .dateTime.day().month().hour().minute())
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text(HistoryText.summary(of: record)).font(.subheadline)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("history.row.\(index)")
                }
            } header: {
                HStack {
                    Text("Historia")
                    Spacer()
                    ShareLink("Eksportuj", item: HistoryExport(records: environment.history.records),
                        preview: SharePreview(HistoryExport.fileName))
                        .accessibilityIdentifier("history.export")
                }
            }
        }
    }

    @ViewBuilder
    private var setRows: some View {
        switch environment.catalog {
        case .success(let catalog):
            ForEach(Array(catalog.sets.enumerated()), id: \.offset) { index, set in
                Button { session = environment.makeSession(set) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.name).font(.headline)
                            Text(PhaseText.summary(of: set)).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .foregroundStyle(.primary)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("start.set.\(index)")
            }
        case .failure(let error):
            Text(error.localizedDescription).foregroundStyle(.red)
        }
    }
}

extension SessionModel: Hashable {
    nonisolated static func == (lhs: SessionModel, rhs: SessionModel) -> Bool { lhs === rhs }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
