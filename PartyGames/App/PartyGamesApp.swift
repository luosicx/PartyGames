import SwiftUI

@main
struct PartyGamesApp: App {
    @StateObject private var adManager = AdConfigManager()
    @State private var showSplashAd = false

    var body: some Scene {
        WindowGroup {
            ContentView(adManager: adManager)
                .overlay {
                    if showSplashAd {
                        SplashAdView(adManager: adManager) {
                            showSplashAd = false
                        }
                        .zIndex(100)
                    }
                }
                .task {
                    await adManager.fetchRemoteConfig()
                    // Short delay to let UI settle before showing ad
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    showSplashAd = adManager.shouldShowSplash
                }
        }
    }
}
