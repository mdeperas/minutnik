import SwiftUI

struct SessionView: View {
    let model: SessionModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var figureZoomed = false
    @State private var zoomToken = 0
    @State private var ringSpin = 0.0
    @State private var instructionsExpanded = false
    @Namespace private var figureSpace

    var body: some View {
        VStack(spacing: 16) {
            header
                .frame(maxWidth: .infinity)
                .layoutPriority(3)
            ring
                .frame(minHeight: 120, maxHeight: model.currentBreath == nil ? 192 : 320)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("session.ring")
                .layoutPriority(2)
            HStack(spacing: 16) {
                figure
                relaxationClock
            }
            .layoutPriority(2)
            instructions
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("session.instructions")
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding()
        .safeAreaInset(edge: .bottom) { controls.padding() }
        .overlay { expandedInstructions }
        .overlay { zoomedFigure }
        .onChange(of: model.currentStep) { instructionsExpanded = false }
        .background(Color(PhaseLook.background).ignoresSafeArea())
        .foregroundStyle(.white)
        .navigationTitle(model.setName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!model.allowsLeaving)
        .toolbar { musicToggle }
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
        if let step = model.currentStep, let breath = model.currentBreath {
            BreathRing(breath: breath, color: Color(PhaseKind.relaxation.ringColor), reduceMotion: reduceMotion)
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
            ZStack {
                Circle()
                    .strokeBorder(Color(PhaseLook.track), lineWidth: 18)
                    .frame(maxWidth: 288)
                Text(stateLabel)
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("session.phase")
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var relaxationClock: some View {
        if model.currentBreath != nil, let phase = model.currentPhaseName, let duration = model.currentPhaseDuration {
            VStack(spacing: 8) {
                Text(phase.uppercased())
                    .font(.headline.bold())
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityLabel(phase)
                    .foregroundStyle(Color(PhaseKind.relaxation.labelColor))
                    .accessibilityIdentifier("session.phase")
                ZStack {
                    SmallPhaseRing(
                        remainingFraction: PhaseLook(phaseName: phase, remaining: model.remainingInPhase, duration: duration, reduceMotion: true).remainingFraction,
                        color: Color(PhaseKind.relaxation.ringColor)
                    )
                    Text(ClockText.minutesSeconds(model.remainingInPhase))
                        .font(.title2.bold())
                        .monospacedDigit()
                        .accessibilityLabel("Zostało \(ClockText.minutesSeconds(model.remainingInPhase))")
                        .accessibilityIdentifier("session.remainingPhase")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var figure: some View {
        if let name = model.currentFigureName {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .frame(maxWidth: .infinity)
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
        ViewThatFits(in: .vertical) {
            instructionLines(font: .body)
            instructionLines(font: .system(size: 15))
            collapsedInstructions
        }
    }

    private func instructionLines(font: Font) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(model.currentInstructions, id: \.label) { line in
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.label).bold().foregroundStyle(labelColor(line.label))
                    Text(line.text).foregroundStyle(Color(PhaseLook.secondaryText))
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(font)
    }

    private var collapsedInstructions: some View {
        Button { instructionsExpanded = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(model.currentInstructions, id: \.label) { line in
                    (Text(line.label + "  ").bold().foregroundColor(labelColor(line.label))
                        + Text(line.text).foregroundColor(Color(PhaseLook.secondaryText)))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("Więcej").bold().foregroundStyle(Color(PhaseLook.secondaryText))
            }
            .font(.system(size: 15))
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("session.instructionsMore")
    }

    @ViewBuilder
    private var expandedInstructions: some View {
        if instructionsExpanded {
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.75).ignoresSafeArea()
                instructionLines(font: .system(size: 15))
                    .padding(20)
                    .background(Color(PhaseLook.background), in: RoundedRectangle(cornerRadius: 16))
                    .padding()
                    .accessibilityIdentifier("session.instructionsExpanded")
            }
            .onTapGesture { instructionsExpanded = false }
            .accessibilityAction(.escape) { instructionsExpanded = false }
        }
    }

    private func labelColor(_ label: String) -> Color {
        guard let kind = model.shownPhaseName.map(PhaseKind.init), kind.highlights(label) else { return .white }
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
                .foregroundStyle(prominent ? Color(PhaseLook.background) : .white)
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

extension SessionView {
    @ToolbarContentBuilder
    private var musicToggle: some ToolbarContent {
        if model.hasMusic {
            ToolbarItem(placement: .topBarTrailing) {
                Button { model.toggleMusic() } label: {
                    MusicNote(muted: model.musicMuted)
                        .foregroundStyle(model.musicMuted ? AnyShapeStyle(Color(LookColor(hex: 0x6B6E76))) : AnyShapeStyle(.tint))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(model.musicMuted ? "Włącz muzykę" : "Wycisz muzykę")
                .accessibilityIdentifier("session.music")
            }
        }
    }
}

private struct MusicNote: View {
    let muted: Bool

    var body: some View {
        ZStack {
            NoteShape().fill()
            if muted { SlashShape().stroke(style: StrokeStyle(lineWidth: 2.2 * 22 / 24, lineCap: .round)) }
        }
        .frame(width: 22, height: 22)
    }
}

private struct NoteShape: Shape {
    func path(in box: CGRect) -> Path {
        let unit = box.width / 24
        func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * unit, y: y * unit) }
        var note = Path()
        note.addEllipse(in: CGRect(x: 4.6 * unit, y: 14.5 * unit, width: 7.6 * unit, height: 6.2 * unit))
        note.addRect(CGRect(x: 10.4 * unit, y: 3.5 * unit, width: 1.9 * unit, height: 14.1 * unit))
        note.addLines([point(12.3, 3.5), point(19.5, 2), point(19.5, 6.2), point(12.3, 7.9)])
        note.closeSubpath()
        return note
    }
}

private struct SlashShape: Shape {
    func path(in box: CGRect) -> Path {
        let unit = box.width / 24
        var slash = Path()
        slash.move(to: CGPoint(x: 3 * unit, y: 3 * unit))
        slash.addLine(to: CGPoint(x: 21 * unit, y: 21 * unit))
        return slash
    }
}
