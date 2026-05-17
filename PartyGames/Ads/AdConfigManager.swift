import SwiftUI

// MARK: - Remote Ad Configuration
struct AdRemoteConfig: Codable {
    var adsEnabled = false
    var splashAd: SplashAdConfig?
    var bannerAd: BannerAdConfig?
}

struct SplashAdConfig: Codable {
    let imageUrl: String?
    let title: String?
    let subtitle: String?
    let linkUrl: String?
    let durationSeconds: Int
    let closeableAfterSeconds: Int

    static let placeholder = SplashAdConfig(
        imageUrl: nil,
        title: "Party Games",
        subtitle: "More fun awaits!",
        linkUrl: nil,
        durationSeconds: 5,
        closeableAfterSeconds: 2
    )
}

struct BannerAdConfig: Codable {
    let text: String
    let linkUrl: String?

    static let placeholder = BannerAdConfig(
        text: "Enjoying Party Games? Share with friends!",
        linkUrl: nil
    )
}

// MARK: - Ad Config Manager
@MainActor
final class AdConfigManager: ObservableObject {
    @Published var config: AdRemoteConfig = AdRemoteConfig()
    @Published var splashAdDismissed = false
    @Published var bannerAdDismissed = false

    private let remoteURL: String
    private let cacheKey = "ad_remote_config_cache"

    init(remoteURL: String? = nil) {
        self.remoteURL = remoteURL
            ?? Bundle.main.object(forInfoDictionaryKey: "AdRemoteConfigURL") as? String
            ?? "https://example.com/ad_config.json"
        self.remoteURL = remoteURL
        loadCached()
    }

    /// Whether splash ad should show: remote says ON, not locally dismissed, config exists
    var shouldShowSplash: Bool {
        config.adsEnabled && config.splashAd != nil && !splashAdDismissed
    }

    /// Whether banner ad should show: remote says ON, not locally dismissed, config exists
    var shouldShowBanner: Bool {
        config.adsEnabled && config.bannerAd != nil && !bannerAdDismissed
    }

    /// Active splash config (remote or placeholder fallback)
    var activeSplashConfig: SplashAdConfig {
        config.splashAd ?? SplashAdConfig.placeholder
    }

    /// Active banner config (remote or placeholder fallback)
    var activeBannerConfig: BannerAdConfig {
        config.bannerAd ?? BannerAdConfig.placeholder
    }

    // MARK: - Remote Fetch
    func fetchRemoteConfig() async {
        guard let url = URL(string: remoteURL) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(AdRemoteConfig.self, from: data)
            config = decoded
            cache(decoded)
        } catch {
            print("Ad remote config fetch failed, using cache: \(error.localizedDescription)")
        }
    }

    // MARK: - Local Dismiss
    func dismissSplash() {
        splashAdDismissed = true
    }

    func dismissBanner() {
        withAnimation(.easeOut(duration: 0.25)) {
            bannerAdDismissed = true
        }
    }

    /// Reset for a new session (e.g., next app launch)
    func resetForNewSession() {
        splashAdDismissed = false
        bannerAdDismissed = false
    }

    // MARK: - Cache
    private func cache(_ config: AdRemoteConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(AdRemoteConfig.self, from: data)
        else { return }
        config = cached
    }
}
