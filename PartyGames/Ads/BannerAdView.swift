import SwiftUI

// MARK: - Custom Banner Ad (Bottom Bar)
struct BannerAdView: View {
    @ObservedObject var adManager: AdConfigManager

    private let config: BannerAdConfig
    @State private var isVisible = false

    init(adManager: AdConfigManager) {
        self.adManager = adManager
        self.config = adManager.activeBannerConfig
    }

    var body: some View {
        Group {
            if isVisible {
                HStack(spacing: 0) {
                    // Content
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.accent)

                        Text(config.text)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Spacer(minLength: 4)
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 4)

                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
                .frame(height: 44)
                .background(AppTheme.surface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppTheme.accent.opacity(0.4))
                        .frame(height: 1)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                isVisible = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            adManager.dismissBanner()
        }
    }
}
