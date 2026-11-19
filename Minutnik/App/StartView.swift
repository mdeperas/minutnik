import SwiftUI

struct StartView: View {
    let environment: AppEnvironment
    @State private var session: SessionModel?

    private let tension = Color(PhaseKind.tension.ringColor)
    private let tensionLabel = Color(PhaseKind.tension.labelColor)
    private let relaxation = Color(PhaseKind.relaxation.ringColor)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                header
                Text("Wybierz zestaw")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                setCards
                Spacer(minLength: 0)
                Text(environment.version.label)
                    .font(.footnote)
                    .foregroundStyle(Color(PhaseLook.secondaryText))
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("start.version")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backdrop.ignoresSafeArea())
            .navigationDestination(item: $session) { SessionView(model: $0) }
        }
        .task { await environment.notifier.requestAuthorization() }
        .loggedScreen("start")
    }

    private var backdrop: some View {
        ZStack {
            Color.black
            RadialGradient(colors: [tension.opacity(0.35), .clear], center: .topLeading, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [relaxation.opacity(0.28), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 380)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TRENING ROZLUŹNIANIA")
                .font(.subheadline.bold())
                .tracking(1.5)
                .foregroundStyle(tensionLabel)
            Text("Minutnik")
                .font(.system(size: 48, weight: .heavy))
                .foregroundStyle(LinearGradient(colors: [tensionLabel, relaxation], startPoint: .leading, endPoint: .trailing))
                .accessibilityIdentifier("start.title")
            HStack(spacing: 8) {
                Circle().fill(tension).frame(width: 12, height: 12)
                Text("napinanie")
                Circle().fill(relaxation).frame(width: 12, height: 12).padding(.leading, 8)
                Text("rozluźnienie")
            }
            .font(.body)
            .foregroundStyle(.white.opacity(0.9))
            .accessibilityElement(children: .combine)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var setCards: some View {
        switch environment.catalog {
        case .success(let catalog):
            ForEach(Array(catalog.sets.enumerated()), id: \.offset) { index, set in
                let color = index.isMultiple(of: 2) ? tension : relaxation
                Button { session = environment.makeSession(set) } label: {
                    SetCard(name: set.name, facts: [PhaseText.minutes(of: set)], color: color)
                }
                .buttonStyle(PressedCardStyle(color: color))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(set.name), \(PhaseText.summary(of: set))")
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("start.set.\(index)")
            }
        case .failure(let error):
            Text(error.localizedDescription).foregroundStyle(.red)
        }
    }
}

private struct SetCard: View {
    let name: String
    let facts: [String]
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(name)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    ForEach(facts, id: \.self) { fact in
                        Text(fact)
                            .font(.headline)
                            .foregroundStyle(color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(color.opacity(0.2)))
                    }
                }
            }
            Spacer(minLength: 0)
            Text("Start ›")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color(PhaseLook.background))
                .padding(.horizontal, 18)
                .frame(minHeight: 48)
                .background(Capsule().fill(color))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color(white: 0.05))
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [color.opacity(0.28), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(color, lineWidth: 2))
        .contentShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct PressedCardStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(color.opacity(0.45))
                    .offset(y: configuration.isPressed ? 2 : 6)
            )
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension SessionModel: Hashable {
    nonisolated static func == (lhs: SessionModel, rhs: SessionModel) -> Bool { lhs === rhs }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
