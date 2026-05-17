import XCTest
@testable import PartyGames

final class GameModelsTests: XCTestCase {

    // MARK: - FlipDifficulty

    func test_flipDifficulty_easy_pairs() {
        XCTAssertEqual(FlipDifficulty.easy.pairs, 6)
        XCTAssertEqual(FlipDifficulty.easy.columns, 3)
    }

    func test_flipDifficulty_medium_pairs() {
        XCTAssertEqual(FlipDifficulty.medium.pairs, 8)
        XCTAssertEqual(FlipDifficulty.medium.columns, 4)
    }

    func test_flipDifficulty_hard_pairs() {
        XCTAssertEqual(FlipDifficulty.hard.pairs, 10)
        XCTAssertEqual(FlipDifficulty.hard.columns, 4)
    }

    func test_flipDifficulty_allCases_unique() {
        let all = FlipDifficulty.allCases
        XCTAssertEqual(all.count, 3)
    }

    func test_flipDifficulty_id() {
        XCTAssertEqual(FlipDifficulty.easy.id, "difficulty_easy")
    }

    // MARK: - CardItem

    func test_cardItem_default_notFlipped_notMatched() {
        let card = CardItem(content: "🎉")
        XCTAssertFalse(card.isFlipped)
        XCTAssertFalse(card.isMatched)
        XCTAssertEqual(card.content, "🎉")
    }

    func test_cardItem_equatable() {
        let a = CardItem(content: "🎉")
        let b = CardItem(content: "🎈")
        XCTAssertNotEqual(a, b)
    }

    // MARK: - RouletteSegment

    func test_rouletteSegment_identity() {
        let seg = RouletteSegment(label: "Test", color: .red)
        XCTAssertEqual(seg.label, "Test")
    }

    // MARK: - RoulettePreset

    func test_truthOrDare_has8Segments() {
        XCTAssertEqual(RoulettePreset.truthOrDare.segments.count, 8)
    }

    func test_partyMoves_has8Segments() {
        XCTAssertEqual(RoulettePreset.partyMoves.segments.count, 8)
    }

    // MARK: - WheelSegment

    func test_wheelSegment_properties() {
        let seg = WheelSegment(label: "P", color: .blue, icon: "star")
        XCTAssertEqual(seg.label, "P")
        XCTAssertEqual(seg.icon, "star")
    }

    // MARK: - FanWheelPreset

    func test_classic_has6Segments() {
        XCTAssertEqual(FanWheelPreset.classic.segments.count, 6)
    }

    func test_challenges_has6Segments() {
        XCTAssertEqual(FanWheelPreset.challenges.segments.count, 6)
    }
}
