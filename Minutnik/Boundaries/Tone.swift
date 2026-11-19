import AVFoundation

enum Tone {
    struct Beep: Equatable {
        let frequency: Double
        let duration: TimeInterval
    }

    static func beeps(for signal: Signal) -> [Beep] {
        switch signal {
        case .phaseStarted(let phaseIndex):
            [Beep(frequency: phaseIndex == 0 ? 880 : 660, duration: 0.25)]
        case .countdown:
            [Beep(frequency: 990, duration: 0.12)]
        case .sessionFinished:
            [Beep(frequency: 660, duration: 0.2), Beep(frequency: 880, duration: 0.2), Beep(frequency: 1_100, duration: 0.4)]
        }
    }

    static func buffer(for signal: Signal, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let gap = Int(rate * 0.08)
        let beeps = beeps(for: signal)
        let total = beeps.reduce(0) { $0 + Int(rate * $1.duration) + gap }
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total))!
        buffer.frameLength = AVAudioFrameCount(total)
        let samples = buffer.floatChannelData![0]
        var offset = 0
        for beep in beeps {
            let length = Int(rate * beep.duration)
            for frame in 0..<length {
                let fade = min(1, Double(min(frame, length - frame)) / (rate * 0.01))
                samples[offset + frame] = Float(0.5 * fade * sin(2 * .pi * beep.frequency * Double(frame) / rate))
            }
            for frame in length..<(length + gap) { samples[offset + frame] = 0 }
            offset += length + gap
        }
        return buffer
    }
}
