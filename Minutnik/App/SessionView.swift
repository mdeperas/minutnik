import SwiftUI

struct SessionView: View {
    let model: SessionModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmsLeaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    header.frame(maxWidth: .infinity)
                    figure
                }
                ring
                instructions
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) { controls.padding() }
        .background(Color(PhaseLook.background).ignoresSafeArea())
        .foregroundStyle(.white)
        .navigationTitle(model.setName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isInProgress)
        .toolbar {
            if model.isInProgress {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Wróć") { confirmsLeaving = true }.accessibilityIdentifier("session.back")
                }
            }
        }
        .alert("Przerwać sesję?", isPresented: $confirmsLeaving) {
            Button("Przerwij", role: .destructive) {
                model.stop()
                dismiss()
            }
            Button("Ćwiczę dalej", role: .cancel) {}
        }
        .sensoryFeedback(.impact, trigger: model.currentStep) { _, step in step != nil }
        .sensoryFeedback(.success, trigger: model.player.state == .finished) { _, finished in finished }
        .onDisappear { model.stop() }
        .loggedScreen("sesja")
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack(spacing: 20) {
                if let position = model.currentGroupPosition {
                    Text(position).accessibilityIdentifier("session.groupPosition")
                }
                Text("Zostało \(ClockText.minutesSeconds(model.remainingInSession))")
                    .monospacedDigit()
                    .accessibilityLabel("Cała sesja: \(ClockText.minutesSeconds(model.remainingInSession))")
                    .accessibilityIdentifier("session.remainingSession")
            }
            .font(.subheadline)
            .foregroundStyle(Color(PhaseLook.secondaryText))
            if let group = model.currentGroupName {
                Text(group).font(.title.bold())
                    .accessibilityIdentifier("session.group")
            }
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var ring: some View {
        if let step = model.currentStep, let phase = model.currentPhaseName, let duration = model.currentPhaseDuration {
            PhaseRing(
                look: PhaseLook(phaseName: phase, remaining: model.remainingInPhase, duration: duration, reduceMotion: reduceMotion),
                phaseName: phase,
                remainingLabel: "Zostało \(ClockText.minutesSeconds(model.remainingInPhase))"
            )
            .id(step)
        } else {
            Text(stateLabel)
                .font(.largeTitle.bold())
                .accessibilityIdentifier("session.phase")
        }
    }

    @ViewBuilder
    private var figure: some View {
        if let name = model.currentFigureName {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .id(name)
                .transition(reduceMotion ? .identity : .opacity)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: name)
                .accessibilityLabel(PhaseKind(phaseName: model.currentPhaseName ?? "") == .tension ? "Rycina: napięcie" : "Rycina: rozluźnienie")
                .accessibilityValue(name)
                .accessibilityIdentifier("session.figure")
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(model.currentInstructions, id: \.label) { line in
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.label).bold().foregroundStyle(labelColor(line.label))
                    Text(line.text).foregroundStyle(Color(PhaseLook.secondaryText))
                }
                .accessibilityElement(children: .combine)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.body)
    }

    private func labelColor(_ label: String) -> Color {
        guard let kind = model.currentPhaseName.map(PhaseKind.init), kind.highlights(label) else { return .white }
        return Color(kind.labelColor)
    }

    @ViewBuilder
    private var controls: some View {
        switch model.player.state {
        case .ready:
            wideButton("Start", id: "session.start", prominent: true) { model.start() }
        case .running, .paused:
            VStack(spacing: 12) {
                if case .paused = model.player.state {
                    wideButton("Wznów", id: "session.resume", prominent: true) { model.resume() }
                } else {
                    wideButton("Pauza", id: "session.pause", prominent: true) { model.pause() }
                }
                HStack(spacing: 12) {
                    wideButton("Pomiń", id: "session.skip") { model.skip() }
                    wideButton("Przerwij", id: "session.stop", role: .destructive) { model.stop() }
                }
            }
        case .finished, .stopped:
            wideButton("Wróć do listy", id: "session.done", prominent: true) { dismiss() }
        }
    }

    @ViewBuilder
    private func wideButton(_ title: String, id: String, prominent: Bool = false, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        let button = Button(role: role, action: action) {
            Text(title).font(.title3.bold()).frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .accessibilityIdentifier(id)
        if prominent { button.buttonStyle(.borderedProminent) } else { button.buttonStyle(.bordered) }
    }

    private var stateLabel: String {
        switch model.player.state {
        case .finished: SessionModel.finishedTitle
        case .stopped: "Przerwano"
        default: "Gotowe"
        }
    }
}
