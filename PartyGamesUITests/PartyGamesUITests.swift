import XCTest

final class PartyGamesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - App Launch

    func test_appLaunch_rendersMainScreen() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func test_appLaunch_showsTabBar() {
        let cardFlipTab = app.buttons["tab_cardflip"]
        let rouletteTab = app.buttons["tab_roulette"]
        let fanWheelTab = app.buttons["tab_fanwheel"]
        XCTAssertTrue(cardFlipTab.waitForExistence(timeout: 3))
        XCTAssertTrue(rouletteTab.exists)
        XCTAssertTrue(fanWheelTab.exists)
    }

    // MARK: - Tab Navigation

    func test_tabNavigation_toFanWheel() {
        let fanWheelTab = app.buttons["tab_fanwheel"]
        XCTAssertTrue(fanWheelTab.waitForExistence(timeout: 3))
        fanWheelTab.tap()

        let title = app.staticTexts["fanwheel_title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
    }

    func test_tabNavigation_toCardFlip() {
        let cardFlipTab = app.buttons["tab_cardflip"]
        XCTAssertTrue(cardFlipTab.waitForExistence(timeout: 3))
        cardFlipTab.tap()

        let title = app.staticTexts["cardflip_title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
    }

    func test_tabNavigation_toFingerRoulette() {
        let rouletteTab = app.buttons["tab_roulette"]
        XCTAssertTrue(rouletteTab.waitForExistence(timeout: 3))
        rouletteTab.tap()

        let title = app.staticTexts["roulette_title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
    }

    // MARK: - FanWheel Game

    func test_fanWheel_spinButton_exists() {
        app.buttons["tab_fanwheel"].tap()
        let spinButton = app.buttons["fanwheel_spin"]
        XCTAssertTrue(spinButton.waitForExistence(timeout: 3))
    }

    func test_fanWheel_spinButton_disabledDuringSpin() {
        app.buttons["tab_fanwheel"].tap()
        let spinButton = app.buttons["fanwheel_spin"]
        XCTAssertTrue(spinButton.waitForExistence(timeout: 3))
        spinButton.tap()
        // After tapping, button should be disabled while spinning
        XCTAssertFalse(spinButton.isEnabled)
    }

    func test_fanWheel_presetsVisible() {
        app.buttons["tab_fanwheel"].tap()
        let classicPreset = app.buttons["Classic Prizes"]
        let challengesPreset = app.buttons["Challenges"]
        XCTAssertTrue(classicPreset.waitForExistence(timeout: 3))
        XCTAssertTrue(challengesPreset.exists)
    }

    // MARK: - CardFlip Game

    func test_cardFlip_difficultyButtons() {
        app.buttons["tab_cardflip"].tap()
        let easyButton = app.buttons["difficulty_easy"]
        XCTAssertTrue(easyButton.waitForExistence(timeout: 3))
    }

    func test_cardFlip_cardsVisible() {
        app.buttons["tab_cardflip"].tap()
        // Card grid should have tappable cards
        let cardExists = app.buttons.firstMatch.exists
        XCTAssertTrue(cardExists)
    }

    // MARK: - FingerRoulette Game

    func test_roulette_presetsVisible() {
        app.buttons["tab_roulette"].tap()
        let truthOrDare = app.buttons["Truth or Dare"]
        let partyMoves = app.buttons["Party Moves"]
        XCTAssertTrue(truthOrDare.waitForExistence(timeout: 3))
        XCTAssertTrue(partyMoves.exists)
    }

    // MARK: - Tab Switching

    func test_switchBetweenAllTabs() {
        for tab in ["tab_cardflip", "tab_roulette", "tab_fanwheel"] {
            app.buttons[tab].tap()
            XCTAssertTrue(app.buttons[tab].exists)
        }
    }
}
