import AVFoundation

/// Every sound is a short procedurally-generated tone (sine waves + an amplitude envelope) —
/// no bundled audio assets. Buffers are built once and cached, so playback is just scheduling.
final class SoundManager {
    static let shared = SoundManager()

    enum Cue {
        case kick, goal, whistle
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var buffers: [Cue: AVAudioPCMBuffer] = [:]
    private let sampleRate = 44_100.0

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) ?? AVAudioFormat()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        buffers[.kick] = tone(frequencies: [150], duration: 0.09, decay: 22, amplitude: 0.6)
        buffers[.goal] = arpeggio(frequencies: [523.25, 659.25, 783.99, 1046.5], noteDuration: 0.11, amplitude: 0.35)
        buffers[.whistle] = tone(frequencies: [2400, 2900], duration: 0.4, decay: 2.2, amplitude: 0.22)
    }

    func play(_ cue: Cue) {
        guard let buffer = buffers[cue] else { return }
        if engine.isRunning == false { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts])
        if !player.isPlaying { player.play() }
    }

    // MARK: - Synthesis

    private func tone(frequencies: [Double], duration: Double, decay: Double, amplitude: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let sample = frequencies.reduce(0.0) { $0 + sin(2 * .pi * $1 * t) } / Double(frequencies.count)
            let envelope = exp(-decay * t)
            channel[frame] = Float(sample * envelope * amplitude)
        }
        return buffer
    }

    /// A short ascending run of notes, back to back — used for the goal cue.
    private func arpeggio(frequencies: [Double], noteDuration: Double, amplitude: Double) -> AVAudioPCMBuffer? {
        let totalFrames = AVAudioFrameCount(sampleRate * noteDuration * Double(frequencies.count))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return nil }
        buffer.frameLength = totalFrames
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let framesPerNote = Int(sampleRate * noteDuration)
        for (noteIndex, frequency) in frequencies.enumerated() {
            for i in 0..<framesPerNote {
                let t = Double(i) / sampleRate
                let envelope = exp(-9 * t)
                let sample = sin(2 * .pi * frequency * t) * envelope * amplitude
                channel[noteIndex * framesPerNote + i] = Float(sample)
            }
        }
        return buffer
    }
}
