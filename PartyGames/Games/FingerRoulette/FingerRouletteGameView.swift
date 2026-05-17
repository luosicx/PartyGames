import SwiftUI

struct FingerRouletteGameView: View {
    @StateObject private var viewModel = FingerRouletteViewModel()
    @State private var lastDragAngle: Double = 0
    @State private var dragVelocity: CGFloat = 0
    @State private var lastDragTime: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            Text(loc("roulette_title"))
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.accent)
                .padding(.top)

            presetPicker
            rouletteWheel
            spinHint
            resultPopup
            Spacer(minLength: 60)
        }
        .padding(.horizontal)
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear { viewModel.selectPreset(0) }
    }

    // MARK: - Preset Picker
    private var presetPicker: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.presets.enumerated()), id: \.offset) { idx, preset in
                Button(preset.name) {
                    viewModel.selectPreset(idx)
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(viewModel.selectedPreset == idx ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewModel.selectedPreset == idx ? AppTheme.secondary : AppTheme.surface)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Wheel
    private var rouletteWheel: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height)
            let radius = diameter / 2

            ZStack {
                // Segments
                ForEach(Array(viewModel.segments.enumerated()), id: \.element.id) { idx, seg in
                    RouletteSlice(
                        startAngle: Angle(degrees: Double(idx) * viewModel.segmentAngle),
                        endAngle: Angle(degrees: Double(idx + 1) * viewModel.segmentAngle),
                        color: seg.color
                    )
                }

                // Labels
                ForEach(Array(viewModel.segments.enumerated()), id: \.element.id) { idx, seg in
                    let midAngle = Angle(degrees: Double(idx) * viewModel.segmentAngle + viewModel.segmentAngle / 2)
                    let labelRadius = radius * 0.62
                    Text(seg.label)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .position(
                            x: radius + CGFloat(cos(midAngle.radians - .pi / 2)) * labelRadius,
                            y: radius + CGFloat(sin(midAngle.radians - .pi / 2)) * labelRadius
                        )
                }

                // Center circle
                Circle()
                    .fill(AppTheme.background)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "hand.draw.fill")
                            .foregroundColor(AppTheme.accent)
                            .font(.title2)
                    )

                // Pointer
                Triangle()
                    .fill(Color.white)
                    .frame(width: 14, height: 20)
                    .offset(y: -radius + 2)
            }
            .rotationEffect(.degrees(viewModel.rotation))
            .frame(width: diameter, height: diameter)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let center = CGPoint(x: diameter / 2, y: diameter / 2)
                        let start = CGPoint(x: value.startLocation.x - center.x,
                                            y: value.startLocation.y - center.y)
                        let current = CGPoint(x: value.location.x - center.x,
                                              y: value.location.y - center.y)
                        let startAngle = atan2(start.y, start.x)
                        let currentAngle = atan2(current.y, current.x)
                        let delta = (currentAngle - startAngle) * 180 / .pi
                        // Accumulate drag rotation visually
                        viewModel.rotation += delta * 0.5
                    }
                    .onEnded { value in
                        let velocity = abs(value.predictedEndLocation.x - value.location.x)
                            + abs(value.predictedEndLocation.y - value.location.y)
                        viewModel.startSpin(from: max(velocity, 5))
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 20)
    }

    // MARK: - Hint
    private var spinHint: some View {
        Text(loc("roulette_hint"))
            .font(AppTheme.captionFont)
            .foregroundColor(AppTheme.textSecondary)
            .padding(.top, 8)
    }

    // MARK: - Result
    @ViewBuilder
    private var resultPopup: some View {
        if viewModel.showResult, let result = viewModel.resultSegment {
            VStack(spacing: 8) {
                Text(loc("roulette_result"))
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
                Text(result.label)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundColor(result.color)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(result.color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.showResult)
            .padding(.top, 16)
        }
    }
}

// MARK: - Slice Shape
struct RouletteSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2
            Path { path in
                path.move(to: center)
                path.addArc(center: center, radius: radius,
                            startAngle: startAngle - .degrees(90),
                            endAngle: endAngle - .degrees(90),
                            clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
            .overlay(
                Path { path in
                    path.move(to: center)
                    path.addArc(center: center, radius: radius,
                                startAngle: startAngle - .degrees(90),
                                endAngle: endAngle - .degrees(90),
                                clockwise: false)
                    path.closeSubpath()
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Triangle Pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
