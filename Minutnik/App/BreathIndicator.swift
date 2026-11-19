import SwiftUI

struct BreathIndicator: View {
    let breath: BoxBreath
    let color: Color
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 4).stroke(Color(PhaseLook.track), lineWidth: 3)
                RoundedRectangle(cornerRadius: 4)
                    .trim(from: 0, to: breath.cycleProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(0.55))
                    .frame(width: 18, height: 18)
                    .scaleEffect(reduceMotion ? 1 : 0.4 + 0.6 * breath.fullness)
                    .animation(reduceMotion ? nil : .linear(duration: 0.25), value: breath.fullness)
            }
            .frame(width: 34, height: 34)
            Text("\(breath.stage.label) \(breath.secondsLeft)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
                .frame(minWidth: 120, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Oddech: \(breath.stage.label), \(breath.secondsLeft)")
        .accessibilityIdentifier("session.breath")
    }
}
