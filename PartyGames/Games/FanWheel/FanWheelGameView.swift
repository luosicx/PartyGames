import SwiftUI

struct FanWheelGameView: View {
    @StateObject private var viewModel = FanWheelViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Text(loc("fanwheel_title"))
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.accent)
                .padding(.top)

            presetPicker
            wheelWithPointer
            spinButton
            resultBanner
            Spacer(minLength: 60)
        }
        .padding(.horizontal)
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear { viewModel.selectPreset(0) }
    }

    // MARK: - Preset
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
                .background(viewModel.selectedPreset == idx ? AppTheme.primary : AppTheme.surface)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Wheel
    private var wheelWithPointer: some View {
        ZStack {
            // Wheel
            GeometryReader { geo in
                let diameter = min(geo.size.width, geo.size.height)
                let radius = diameter / 2
                ZStack {
                    ForEach(Array(viewModel.segments.enumerated()), id: \.element.id) { idx, seg in
                        FanSlice(
                            startAngle: Angle(degrees: Double(idx) * viewModel.segmentAngle),
                            endAngle: Angle(degrees: Double(idx + 1) * viewModel.segmentAngle),
                            color: seg.color
                        )
                    }

                    // Icons & labels on wheel
                    ForEach(Array(viewModel.segments.enumerated()), id: \.element.id) { idx, seg in
                        let midAngle = Angle(degrees: Double(idx) * viewModel.segmentAngle + viewModel.segmentAngle / 2)
                        let iconRadius = radius * 0.55
                        let labelRadius = radius * 0.78
                        VStack(spacing: 2) {
                            Image(systemName: seg.icon)
                                .font(.system(size: 16, weight: .bold))
                            Text(seg.label)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .position(
                            x: radius + CGFloat(cos(midAngle.radians - .pi / 2)) * iconRadius,
                            y: radius + CGFloat(sin(midAngle.radians - .pi / 2)) * iconRadius
                        )
                    }

                    // Center hub
                    Circle()
                        .fill(AppTheme.gold)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                        .overlay(
                            Image(systemName: "star.fill")
                                .foregroundColor(.white)
                                .font(.title3)
                        )
                        .shadow(color: AppTheme.gold.opacity(0.5), radius: 8)
                }
                .rotationEffect(.degrees(viewModel.rotation))
                .frame(width: diameter, height: diameter)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }

            // Pointer at top
            VStack(spacing: 0) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.gold)
                    .shadow(color: AppTheme.gold.opacity(0.6), radius: 4)
                Spacer()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 12)
    }

    // MARK: - Spin Button
    private var spinButton: some View {
        Button {
            viewModel.spin()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                Text(loc("fanwheel_spin"))
            }
        }
        .buttonStyle(PartyButtonStyle(color: viewModel.isSpinning ? Color.gray : AppTheme.primary))
        .disabled(viewModel.isSpinning)
        .padding(.top, 16)
        .pulse()
    }

    // MARK: - Result
    @ViewBuilder
    private var resultBanner: some View {
        if viewModel.showResult, let result = viewModel.resultSegment {
            HStack(spacing: 12) {
                Image(systemName: result.icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("fanwheel_result"))
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(result.label)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding()
            .background(result.color.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(result.color, lineWidth: 1)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showResult)
            .padding(.top, 16)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Fan Slice
struct FanSlice: View {
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
                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            )
        }
    }
}
