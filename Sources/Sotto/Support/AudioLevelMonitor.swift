import AVFoundation
import Combine
import Foundation

// @unchecked Sendable is safe here: all @Published mutations are dispatched
// to MainActor via DispatchQueue.main.async, and normalizedLevel is a
// nonisolated pure function that runs on the Core Audio tap queue.
final class AudioLevelMonitor: ObservableObject, @unchecked Sendable {
    @Published private(set) var level: Double = 0
    @Published private(set) var isListening = false
    @Published private(set) var permissionStatus: AVAuthorizationStatus = .notDetermined

    private let engine = AVAudioEngine()
    private var hasInputTap = false

    func start() {
        guard !isListening else { return }

        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        permissionStatus = status

        switch status {
        case .authorized:
            startEngine()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                    guard granted else {
                        self?.level = 0
                        self?.isListening = false
                        return
                    }
                    self?.startEngine()
                }
            }
        case .denied, .restricted:
            level = 0
            isListening = false
        @unknown default:
            level = 0
            isListening = false
        }
    }

    func stop() {
        if hasInputTap {
            engine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        engine.stop()
        isListening = false
        level = 0
    }

    private func startEngine() {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        if hasInputTap {
            input.removeTap(onBus: 0)
        }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            let nextLevel = Self.normalizedLevel(from: buffer)
            DispatchQueue.main.async {
                guard let self else { return }
                self.level = self.level * 0.45 + nextLevel * 0.55
            }
        }
        hasInputTap = true

        do {
            engine.prepare()
            try engine.start()
            isListening = true
        } catch {
            stop()
        }
    }

    nonisolated private static func normalizedLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        let channelCount = max(1, Int(buffer.format.channelCount))
        var sum: Float = 0

        for channelIndex in 0..<channelCount {
            let samples = channelData[channelIndex]
            for frameIndex in 0..<frameLength {
                let sample = samples[frameIndex]
                sum += sample * sample
            }
        }

        let meanSquare = sum / Float(frameLength * channelCount)
        let rootMeanSquare = max(sqrt(meanSquare), 0.000_001)
        let decibels = 20 * log10(rootMeanSquare)
        return min(max((Double(decibels) + 60) / 50, 0), 1)
    }
}
