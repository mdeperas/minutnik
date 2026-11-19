import SwiftUI

struct SessionView: View {
    let model: SessionModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var figureZoomed = false
    @State private var zoomToken = 0
    @State private var ringSpin = 0.0
    @Namespace private var figureSpace

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                header.frame(maxWidth: .infinity)
                figure
            }
            .layoutPriority(1)
            ring
                .frame(minHeight: 96, maxHeight: .infinity)
            instructions
                .layoutPriority(1)
        }
        .padding()
        .safeAreaInset(edge: .bottom) { controls.padding() }
        .overlay { zoomedFigure }
        .background(Color(PhaseLook.background).ignoresSafeArea())
        .foregroundStyle(.white)
        .navigationTitle(model.setName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isInProgress)
        .onChange(of: model.currentStep) { old, new in
            guard old != nil, new != nil, !reduceMotion else { return }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9)) { ringSpin += 360 }
        }
        .onChange(of: model.currentFigureName) { closeFigure() }
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
        if let step = model.currentStep, let phase = model.currentPhaseName, let breath = model.currentBreath, let duration = model.currentPhaseDuration {
            VStack(spacing: 8) {
                BreathRing(
                    breath: breath,
                    phaseRemainingFraction: PhaseLook(phaseName: phase, remaining: model.remainingInPhase, duration: duration, reduceMotion: true).remainingFraction,
                    color: Color(PhaseKind.relaxation.ringColor),
                    reduceMotion: reduceMotion
                )
                    .layoutPriority(1)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(phase)
                        .font(.headline)
                        .foregroundStyle(Color(PhaseKind.relaxation.labelColor))
                        .accessibilityIdentifier("session.phase")
                    Text(ClockText.minutesSeconds(model.remainingInPhase))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                        .accessibilityLabel("Zostało \(ClockText.minutesSeconds(model.remainingInPhase))")
                        .accessibilityIdentifier("session.remainingPhase")
                }
            }
            .id(step)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.6), value: step)
        } else if let step = model.currentStep, let phase = model.currentPhaseName, let duration = model.currentPhaseDuration {
            PhaseRing(
                look: PhaseLook(phaseName: phase, remaining: model.remainingInPhase, duration: duration, reduceMotion: reduceMotion),
                phaseName: phase,
                remainingLabel: "Zostało \(ClockText.minutesSeconds(model.remainingInPhase))",
                spin: ringSpin
            )
            .id(step)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.6), value: step)
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
                .modifier(FigureMatch(id: name, space: figureSpace, isSource: !figureZoomed, enabled: !reduceMotion))
                .opacity(figureZoomed ? 0 : 1)
                .id(name)
                .transition(reduceMotion ? .identity : .opacity)
                .onTapGesture { toggleFigure() }
                .accessibilityRemoveTraits(.isButton)
                .accessibilityAddTraits(.isImage)
                .accessibilityAction { toggleFigure() }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: name)
                .accessibilityLabel(PhaseKind(phaseName: model.currentPhaseName ?? "") == .tension ? "Rycina: napięcie" : "Rycina: rozluźnienie")
                .accessibilityValue(name)
                .accessibilityIdentifier("session.figure")
        }
    }

    @ViewBuilder
    private var zoomedFigure: some View {
        if figureZoomed, let name = model.currentFigureName {
            ZStack {
                Color.black.opacity(0.75).ignoresSafeArea()
                    .transition(.opacity)
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .modifier(FigureMatch(id: name, space: figureSpace, isSource: true, enabled: !reduceMotion))
                    .padding(24)
                    .transition(reduceMotion ? .opacity : .identity)
                    .accessibilityIdentifier("session.figureZoomed")
            }
            .onTapGesture { closeFigure() }
        }
    }

    private var figureAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.5, dampingFraction: 0.72)
    }

    private func toggleFigure() {
        guard !figureZoomed else { return closeFigure() }
        withAnimation(figureAnimation) { figureZoomed = true }
        zoomToken += 1
        let token = zoomToken
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if token == zoomToken { closeFigure() }
        }
    }

    private func closeFigure() {
        guard figureZoomed else { return }
        zoomToken += 1
        withAnimation(figureAnimation) { figureZoomed = false }
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
        .minimumScaleFactor(0.8)
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

private struct FigureMatch: ViewModifier {
    let id: String
    let space: Namespace.ID
    let isSource: Bool
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.matchedGeometryEffect(id: id, in: space, isSource: isSource)
        } else {
            content
        }
    }
}
