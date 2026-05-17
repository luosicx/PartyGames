import SwiftUI

@MainActor
final class FingerRouletteViewModel: ObservableObject {
    @Published var segments: [RouletteSegment] = []
    @Published var rotation: Double = 0
    @Published var isSpinning = false
    @Published var resultSegment: RouletteSegment?
    @Published var showResult = false
    @Published var selectedPreset = 0

    private var angularVelocity: Double = 0
    private var displayLink: Timer?

    let presets = [RoulettePreset.truthOrDare, RoulettePreset.partyMoves]

    var segmentAngle: Double { 360.0 / Double(segments.count) }

    func selectPreset(_ index: Int) {
        selectedPreset = index
        segments = presets[index].segments
    }

    func startSpin(from velocity: CGFloat) {
        guard !isSpinning else { return }
        isSpinning = true
        showResult = false
        resultSegment = nil

        angularVelocity = min(max(Double(velocity) / 100.0, 5), 40)

        displayLink?.invalidate()
        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        rotation += angularVelocity
        angularVelocity *= 0.985

        if angularVelocity < 0.3 {
            angularVelocity = 0
            displayLink?.invalidate()
            displayLink = nil
            isSpinning = false
            determineResult()
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
