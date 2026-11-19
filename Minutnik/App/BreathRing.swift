import SwiftUI

struct BreathRing: View {
    let breath: BoxBreath
    let phaseRemainingFraction: Double
    let color: Color
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let line = side * PhaseLook.ringLineFraction
            ZStack {
                Circle()
                    .fill(color.opacity(0.22))
                    .padding(line * 1.5)
                    .scaleEffect(reduceMotion ? 1 : 0.4 + 0.6 * breath.fullness)
                    .animation(reduceMotion ? nil : .linear(duration: 0.25), value: breath.fullness)
                ZStack {
                    Circle().stroke(Color(PhaseLook.track), lineWidth: line)
                    Circle()
                        .trim(from: 0, to: phaseRemainingFraction)
                        .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.25), value: phaseRemainingFraction)
                }
                .padding(line / 2)
                VStack(spacing: side * 0.03) {
                    Text("\(breath.secondsLeft)")
                        .font(.system(size: side * 0.3, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                    Text(breath.stage.label)
                        .font(.system(size: side * 0.09, weight: .bold))
                        .foregroundStyle(color)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 288)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Oddech: \(breath.stage.label), \(breath.secondsLeft)")
        .accessibilityIdentifier("session.breath")
    }
}
