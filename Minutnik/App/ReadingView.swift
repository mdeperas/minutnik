import SwiftUI

struct ReadingView: View {
    let text: Result<ReadingText, Error>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                switch text {
                case .success(let text):
                    ForEach(Array(text.sections.enumerated()), id: \.offset) { _, section in
                        ReadingSectionView(section: section)
                    }
                    Text(text.source)
                        .font(.callout.italic())
                        .foregroundStyle(Color(PhaseLook.secondaryText))
                        .accessibilityIdentifier("reading.source")
                case .failure(let error):
                    Text(error.localizedDescription).foregroundStyle(.red)
                }
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .loggedScreen("o-cwiczeniu")
    }

    private var title: String {
        (try? text.get().title) ?? "O ćwiczeniu"
    }
}

private struct ReadingSectionView: View {
    let section: ReadingSection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.heading)
                .font(.title3.bold())
                .foregroundStyle(Color(PhaseKind.tension.labelColor))
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
            }
            ForEach(Array(section.points.enumerated()), id: \.offset) { _, point in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("•").foregroundStyle(Color(PhaseKind.relaxation.ringColor)).accessibilityHidden(true)
                    Text(point)
                }
            }
        }
        .font(.body)
        .lineSpacing(5)
        .foregroundStyle(.white.opacity(0.92))
        .fixedSize(horizontal: false, vertical: true)
    }
}
