import Foundation

struct LookColor: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    init(hue: Double, saturation: Double, lightness: Double) {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let sector = hue / 60
        let second = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
        let base = lightness - chroma / 2
        let (r, g, b): (Double, Double, Double) = switch Int(sector) % 6 {
        case 0: (chroma, second, 0)
        case 1: (second, chroma, 0)
        case 2: (0, chroma, second)
        case 3: (0, second, chroma)
        case 4: (second, 0, chroma)
        default: (chroma, 0, second)
        }
        red = r + base
        green = g + base
        blue = b + base
    }
}

enum PhaseKind: Equatable {
    case tension
    case relaxation

    init(phaseName: String) {
        self = phaseName.lowercased().hasPrefix("napin") ? .tension : .relaxation
    }

    var ringColor: LookColor {
        switch self {
        case .tension: LookColor(hue: PhaseLook.tensionHue, saturation: 0.8, lightness: 0.64)
        case .relaxation: PhaseLook.relaxationColor
        }
    }

    var labelColor: LookColor {
        switch self {
        case .tension: LookColor(hue: PhaseLook.tensionHue, saturation: 0.9, lightness: 0.84)
        case .relaxation: PhaseLook.relaxationColor
        }
    }

    func highlights(_ instructionLabel: String) -> Bool {
        switch self {
        case .tension: instructionLabel == "Napnij"
        case .relaxation: ["Puść", "Poczuj"].contains(instructionLabel)
        }
    }
}

struct PhaseLook: Equatable {
    static let background = LookColor(hex: 0x17181C)
    static let track = LookColor(hex: 0x353841)
    static let secondaryText = LookColor(hex: 0xC1C3C8)
    static let ringLineFraction = 10.0 / 200
    static let smallestScale = 0.8
    static let tensionHue = 190.0
    static let relaxationColor = LookColor(hex: 0x8FBFA3)

    let kind: PhaseKind
    let remainingFraction: Double
    let scale: Double
    let digits: String

    init(phaseName: String, remaining: TimeInterval, duration: TimeInterval, reduceMotion: Bool) {
        kind = PhaseKind(phaseName: phaseName)
        let elapsed = duration > 0 ? min(1, max(0, 1 - remaining / duration)) : 1
        remainingFraction = 1 - elapsed
        let shrink = (1 - Self.smallestScale) * elapsed
        scale = reduceMotion ? 1 : kind == .tension ? 1 - shrink : Self.smallestScale + shrink
        let seconds = Int(max(0, remaining).rounded(.up))
        digits = seconds < 60 ? "\(seconds)" : ClockText.minutesSeconds(remaining)
    }
}
