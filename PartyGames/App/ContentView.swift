import SwiftUI

struct ContentView: View {
    @ObservedObject var adManager: AdConfigManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                CardFlipGameView()
                    .tag(0)
                FingerRouletteGameView()
                    .tag(1)
                FanWheelGameView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            customTabBar
        }
        .background(AppTheme.background)
        .preferredColorScheme(.dark)
    }

    // MARK: - Tab Bar
    private var customTabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tabButton(index: 0, icon: "rectangle.on.rectangle.angled", title: loc("tab_cardflip"))
                tabButton(index: 1, icon: "circle.circle",              title: loc("tab_roulette"))
                tabButton(index: 2, icon: "gearshape.2",                title: loc("tab_fanwheel"))
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(AppTheme.surface)

            // Custom banner ad with close button
            if adManager.shouldShowBanner {
                BannerAdView(adManager: adManager)
            }
        }
    }

    private func tabButton(index: Int, icon: String, title: LocalizedStringKey) -> some View {
        Button {
            withAnimation { selectedTab = index }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundColor(selectedTab == index ? AppTheme.accent : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}
