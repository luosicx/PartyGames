import XCTest
@testable import PartyGames

@MainActor
final class AdConfigManagerTests: XCTestCase {
    var adManager: AdConfigManager!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "ad_remote_config_cache")
        adManager = AdConfigManager(remoteURL: "https://example.com/ad_config.json")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "ad_remote_config_cache")
        adManager = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func test_initialState_adsDisabled() {
        XCTAssertFalse(adManager.config.adsEnabled)
        XCTAssertFalse(adManager.splashAdDismissed)
        XCTAssertFalse(adManager.bannerAdDismissed)
    }

    // MARK: - shouldShowSplash

    func test_shouldShowSplash_whenAdsDisabled_returnsFalse() {
        adManager.config = AdRemoteConfig(adsEnabled: false, splashAd: SplashAdConfig.placeholder)
        XCTAssertFalse(adManager.shouldShowSplash)
    }

    func test_shouldShowSplash_whenAdsEnabledAndSplashExists_returnsTrue() {
        adManager.config = AdRemoteConfig(adsEnabled: true, splashAd: SplashAdConfig.placeholder)
        XCTAssertTrue(adManager.shouldShowSplash)
    }

    func test_shouldShowSplash_whenDismissed_returnsFalse() {
        adManager.config = AdRemoteConfig(adsEnabled: true, splashAd: SplashAdConfig.placeholder)
        adManager.dismissSplash()
        XCTAssertFalse(adManager.shouldShowSplash)
    }

    func test_shouldShowSplash_whenNoSplashConfig_returnsFalse() {
        adManager.config = AdRemoteConfig(adsEnabled: true, splashAd: nil)
        XCTAssertFalse(adManager.shouldShowSplash)
    }

    // MARK: - shouldShowBanner

    func test_shouldShowBanner_whenAdsDisabled_returnsFalse() {
        adManager.config = AdRemoteConfig(adsEnabled: false, bannerAd: BannerAdConfig.placeholder)
        XCTAssertFalse(adManager.shouldShowBanner)
    }

    func test_shouldShowBanner_whenAdsEnabledAndBannerExists_returnsTrue() {
        adManager.config = AdRemoteConfig(adsEnabled: true, bannerAd: BannerAdConfig.placeholder)
        XCTAssertTrue(adManager.shouldShowBanner)
    }

    func test_shouldShowBanner_whenDismissed_returnsFalse() {
        adManager.config = AdRemoteConfig(adsEnabled: true, bannerAd: BannerAdConfig.placeholder)
        adManager.dismissBanner()
        XCTAssertTrue(adManager.bannerAdDismissed)
    }

    // MARK: - dismiss

    func test_dismissSplash_setsDismissed() {
        adManager.dismissSplash()
        XCTAssertTrue(adManager.splashAdDismissed)
    }

    func test_dismissBanner_setsDismissed() {
        adManager.dismissBanner()
        XCTAssertTrue(adManager.bannerAdDismissed)
    }

    // MARK: - resetForNewSession

    func test_resetForNewSession_clearsDismissed() {
        adManager.dismissSplash()
        adManager.dismissBanner()
        adManager.resetForNewSession()

        XCTAssertFalse(adManager.splashAdDismissed)
        XCTAssertFalse(adManager.bannerAdDismissed)
    }

    // MARK: - activeConfig fallbacks

    func test_activeSplashConfig_returnsPlaceholderWhenNil() {
        adManager.config = AdRemoteConfig(adsEnabled: false, splashAd: nil)
        let config = adManager.activeSplashConfig
        XCTAssertEqual(config.title, "Party Games")
    }

    func test_activeSplashConfig_returnsRemoteWhenSet() {
        let remote = SplashAdConfig(imageUrl: "u", title: "T", subtitle: "S", linkUrl: nil, durationSeconds: 3, closeableAfterSeconds: 1)
        adManager.config = AdRemoteConfig(adsEnabled: true, splashAd: remote)
        XCTAssertEqual(adManager.activeSplashConfig.title, "T")
    }

    func test_activeBannerConfig_returnsPlaceholderWhenNil() {
        adManager.config = AdRemoteConfig(adsEnabled: false, bannerAd: nil)
        XCTAssertEqual(adManager.activeBannerConfig.text, "Enjoying Party Games? Share with friends!")
    }
}
