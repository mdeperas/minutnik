import SwiftUI

extension Color {
    init(_ look: LookColor) {
        self.init(red: look.red, green: look.green, blue: look.blue)
    }
}

struct PhaseRing: View {
    let look: PhaseLook
    let phaseName: String
    let remainingLabel: String
    var spin: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let line = side * PhaseLook.ringLineFraction
            ZStack {
                ZStack {
                    Circle().stroke(Color(PhaseLook.track), lineWidth: line)
                    Circle()
                        .trim(from: 0, to: look.remainingFraction)
                        .stroke(Color(look.kind.ringColor), style: StrokeStyle(lineWidth: line, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .padding(line / 2)
                .rotationEffect(.degrees(spin))
                .scaleEffect(look.scale)
                .animation(.linear(duration: 0.25), value: look)
                VStack(spacing: side * 0.03) {
                    Text(look.digits)
                        .font(.system(size: side * 0.24, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .accessibilityLabel(remainingLabel)
                        .accessibilityIdentifier("session.remainingPhase")
                    Text(phaseName.uppercased())
                        .font(.system(size: side * 0.06, weight: .bold))
                        .tracking(side * 0.06 * 0.04)
                        .foregroundStyle(Color(look.kind.labelColor))
                        .accessibilityLabel(phaseName)
                        .accessibilityIdentifier("session.phase")
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: side * PhaseLook.smallestScale * 0.75)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 288)
    }
}
