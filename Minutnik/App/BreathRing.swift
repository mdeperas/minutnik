import SwiftUI

struct BreathRing: View {
    let breath: BoxBreath
    let color: Color
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let line = side * PhaseLook.ringLineFraction * 0.5
            ZStack {
                Circle()
                    .fill(color.opacity(0.22))
                    .scaleEffect(breath.lungScale(reduceMotion: reduceMotion))
                    .animation(reduceMotion ? nil : .linear(duration: 0.25), value: breath.fullness)
                Circle().stroke(Color(PhaseLook.track), lineWidth: line)
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
        .frame(maxWidth: 320)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Oddech: \(breath.stage.label), \(breath.secondsLeft)")
        .accessibilityIdentifier("session.breath")
    }
}

struct SmallPhaseRing: View {
    let remainingFraction: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(Color(PhaseLook.track), lineWidth: 6)
            Circle()
                .trim(from: 0, to: remainingFraction)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: remainingFraction)
        }
        .padding(3)
        .frame(width: 88, height: 88)
    }
}
