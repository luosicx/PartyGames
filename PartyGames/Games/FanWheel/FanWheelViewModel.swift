import SwiftUI

@MainActor
final class FanWheelViewModel: ObservableObject {
    @Published var segments: [WheelSegment] = []
    @Published var rotation: Double = 0
    @Published var isSpinning = false
    @Published var resultSegment: WheelSegment?
    @Published var showResult = false
    @Published var selectedPreset = 0

    private var angularVelocity: Double = 0
    private var targetAngle: Double = 0
    private var displayLink: Timer?

    let presets = [FanWheelPreset.classic, FanWheelPreset.challenges]

    var segmentAngle: Double { 360.0 / Double(segments.count) }

    func selectPreset(_ index: Int) {
        selectedPreset = index
        segments = presets[index].segments
    }

    func spin() {
        guard !isSpinning else { return }
        isSpinning = true
        showResult = false
        resultSegment = nil

        let extraSpins = Double.random(in: 5...10) * 360
        targetAngle = rotation + extraSpins + Double.random(in: 0...360)
        angularVelocity = Double.random(in: 15...30)

        displayLink?.invalidate()
        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        let remaining = targetAngle - rotation
        if abs(remaining) < 1 && angularVelocity < 0.5 {
            rotation = targetAngle
            angularVelocity = 0
            displayLink?.invalidate()
            displayLink = nil
            isSpinning = false
            determineResult()
        } else {
            // Ease-out toward target
            angularVelocity *= 0.98
            let step = max(remaining * 0.08, angularVelocity)
            rotation += step
        }
    }

    private func determineResult() {
        let normalized = rotation.truncatingRemainder(dividingBy: 360)
        let adjusted = (360 - normalized).truncatingRemainder(dividingBy: 360)
        let index = Int(adjusted / segmentAngle) % segments.count
        resultSegment = segments[index]
        showResult = true
    }
}
