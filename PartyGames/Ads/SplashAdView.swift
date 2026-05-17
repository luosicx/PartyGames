import SwiftUI

// MARK: - Custom Splash Ad (Full-Screen)
struct SplashAdView: View {
    @ObservedObject var adManager: AdConfigManager
    var onDismiss: () -> Void

    @State private var countdown: Int = 5
    @State private var canDismiss = false
    @State private var timer: Timer?
    @State private var opacity: Double = 0

    private let config: SplashAdConfig

    init(adManager: AdConfigManager, onDismiss: @escaping () -> Void) {
        self.adManager = adManager
        self.onDismiss = onDismiss
        self.config = adManager.activeSplashConfig
        self._countdown = State(initialValue: config.durationSeconds)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [AppTheme.background, AppTheme.surface, AppTheme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 72))
                    .foregroundColor(AppTheme.accent)
                    .pulse()

                // Title
                Text(config.title ?? "Party Games")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundColor(.white)

                // Subtitle
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.system(.title2, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // Countdown or Close
                if canDismiss {
                    closeButton
                } else {
                    countdownIndicator
                }

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { opacity = 1 }
            startCountdown()
        }
    }

    // MARK: - Countdown
    private var countdownIndicator: some View {
        VStack(spacing: 12) {
            ProgressView(value: Double(config.durationSeconds - countdown),
                         total: Double(config.durationSeconds))
                .tint(AppTheme.accent)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal, 40)
            Text("\(locString("splash_wait")) \(countdown)s")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Close Button
    private var closeButton: some View {
        Button(action: dismiss) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                Text(loc("splash_close"))
            }
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .background(AppTheme.primary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Timer
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if countdown > 0 {
                    countdown -= 1
                }
                if countdown <= max(0, config.durationSeconds - config.closeableAfterSeconds) {
                    canDismiss = true
                }
                if countdown == 0 {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        timer?.invalidate()
        adManager.dismissSplash()
        withAnimation(.easeOut(duration: 0.25)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
    }
}
