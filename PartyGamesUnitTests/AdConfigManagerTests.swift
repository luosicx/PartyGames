import XCTest
@testable import PartyGames

// MARK: - Mocks

final class MockURLSession: URLSessionProviding, @unchecked Sendable {
    var mockData: Data?
    var mockError: Error?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = mockError { throw error }
        let data = mockData ?? Data()
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
        return (data, response)
    }
}

final class MockKeyValueStorage: KeyValueStorageProviding, @unchecked Sendable {
    var store: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        store[key]
    }

    func set(_ data: Data?, forKey key: String) {
        store[key] = data
    }
}

// MARK: - Tests

@MainActor
final class AdConfigManagerTests: XCTestCase {
    var adManager: AdConfigManager!
    var mockSession: MockURLSession!
    var mockStorage: MockKeyValueStorage!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        mockStorage = MockKeyValueStorage()
        adManager = AdConfigManager(
            remoteURL: "https://example.com/ad_config.json",
            urlSession: mockSession,
            storage: mockStorage
        )
    }

    override func tearDown() {
        adManager = nil
        mockSession = nil
        mockStorage = nil
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

    // MARK: - fetchRemoteConfig (network)

    func test_fetchRemoteConfig_decodesAndUpdatesConfig() async {
        let remote = AdRemoteConfig(adsEnabled: true, splashAd: SplashAdConfig.placeholder)
        mockSession.mockData = try! JSONEncoder().encode(remote)

        await adManager.fetchRemoteConfig()

        XCTAssertTrue(adManager.config.adsEnabled)
        XCTAssertNotNil(adManager.config.splashAd)
    }

    func test_fetchRemoteConfig_networkError_keepsExistingConfig() async {
        adManager.config = AdRemoteConfig(adsEnabled: true, splashAd: SplashAdConfig.placeholder)
        mockSession.mockError = URLError(.notConnectedToInternet)

        await adManager.fetchRemoteConfig()

        // Config unchanged after network failure
        XCTAssertTrue(adManager.config.adsEnabled)
    }

    func test_fetchRemoteConfig_invalidJSON_keepsExistingConfig() async {
        adManager.config = AdRemoteConfig(adsEnabled: false)
        mockSession.mockData = Data("not json".utf8)

        await adManager.fetchRemoteConfig()

        XCTAssertFalse(adManager.config.adsEnabled)
    }

    // MARK: - cache

    func test_fetchRemoteConfig_cachesToStorage() async {
        let remote = AdRemoteConfig(adsEnabled: true)
        mockSession.mockData = try! JSONEncoder().encode(remote)

        await adManager.fetchRemoteConfig()

        XCTAssertNotNil(mockStorage.store["ad_remote_config_cache"])
    }

    func test_init_loadsCachedConfig() {
        let cached = AdRemoteConfig(adsEnabled: true, bannerAd: BannerAdConfig.placeholder)
        let data = try! JSONEncoder().encode(cached)
        mockStorage.store["ad_remote_config_cache"] = data

        let manager = AdConfigManager(
            remoteURL: "https://example.com/ad_config.json",
            urlSession: mockSession,
            storage: mockStorage
        )

        XCTAssertTrue(manager.config.adsEnabled)
        XCTAssertNotNil(manager.config.bannerAd)
    }

    func test_init_noCache_startsFresh() {
        let manager = AdConfigManager(
            remoteURL: "https://example.com/ad_config.json",
            urlSession: mockSession,
            storage: mockStorage
        )

        XCTAssertFalse(manager.config.adsEnabled)
    }
}
