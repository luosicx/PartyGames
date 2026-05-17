import XCTest
@testable import PartyGames

@MainActor
final class CardFlipViewModelTests: XCTestCase {
    var vm: CardFlipViewModel!

    override func setUp() {
        super.setUp()
        vm = CardFlipViewModel()
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        XCTAssertTrue(vm.cards.isEmpty)
        XCTAssertEqual(vm.flipCount, 0)
        XCTAssertEqual(vm.matchedPairs, 0)
        XCTAssertFalse(vm.isGameComplete)
        XCTAssertEqual(vm.elapsedTime, 0)
    }

    // MARK: - startGame

    func test_startGameEasy_creates12Cards() {
        vm.setDifficulty(.easy)
        XCTAssertEqual(vm.cards.count, 12)
        XCTAssertEqual(vm.totalPairs, 6)
    }

    func test_startGameMedium_creates16Cards() {
        vm.setDifficulty(.medium)
        XCTAssertEqual(vm.cards.count, 16)
        XCTAssertEqual(vm.totalPairs, 8)
    }

    func test_startGameHard_creates20Cards() {
        vm.setDifficulty(.hard)
        XCTAssertEqual(vm.cards.count, 20)
        XCTAssertEqual(vm.totalPairs, 10)
    }

    func test_startGame_cardsAreShuffled() {
        vm.setDifficulty(.easy)
        // Verify pairs exist (each emoji appears exactly twice)
        let contents = vm.cards.map(\.content)
        let counts = Dictionary(grouping: contents, by: { $0 }).mapValues(\.count)
        XCTAssertEqual(counts.count, 6)
        XCTAssertTrue(counts.values.allSatisfy { $0 == 2 })
    }

    func test_startGame_allCardsFaceDown() {
        vm.setDifficulty(.easy)
        XCTAssertTrue(vm.cards.allSatisfy { !$0.isFlipped && !$0.isMatched })
    }

    func test_startGame_resetsState() {
        vm.setDifficulty(.easy)
        vm.tapCard(at: 0)
        vm.setDifficulty(.medium)

        XCTAssertEqual(vm.flipCount, 0)
        XCTAssertEqual(vm.matchedPairs, 0)
        XCTAssertFalse(vm.isGameComplete)
    }

    // MARK: - tapCard

    func test_tapCard_flipsCardUp() {
        vm.setDifficulty(.easy)
        vm.tapCard(at: 0)
        XCTAssertTrue(vm.cards[0].isFlipped)
        XCTAssertEqual(vm.flipCount, 1)
    }

    func test_tapCard_cannotFlipFlippedCard() {
        vm.setDifficulty(.easy)
        vm.tapCard(at: 0)
        let afterFirst = vm.cards[0].isFlipped
        vm.tapCard(at: 0)
        XCTAssertTrue(afterFirst)
        XCTAssertEqual(vm.flipCount, 1) // count stays
    }

    func test_tapCard_match() {
        vm.setDifficulty(.easy)
        // Find first card's pair
        let firstContent = vm.cards[0].content
        guard let pairIndex = vm.cards.indices.first(where: { $0 != 0 && vm.cards[$0].content == firstContent }) else {
            XCTFail("Pair not found")
            return
        }

        vm.tapCard(at: 0)
        vm.tapCard(at: pairIndex)

        XCTAssertTrue(vm.cards[0].isMatched)
        XCTAssertTrue(vm.cards[pairIndex].isMatched)
        XCTAssertEqual(vm.matchedPairs, 1)
    }

    func test_tapCard_mismatch_flipsBack() {
        vm.setDifficulty(.easy)
        guard let mismatchIndex = vm.cards.indices.first(where: { vm.cards[$0].content != vm.cards[0].content }) else {
            XCTFail("Mismatch index not found")
            return
        }

        vm.tapCard(at: 0)
        vm.tapCard(at: mismatchIndex)

        // Immediately after, second card should be flipped
        XCTAssertTrue(vm.cards[mismatchIndex].isFlipped)
        XCTAssertFalse(vm.cards[0].isMatched)
        XCTAssertFalse(vm.cards[mismatchIndex].isMatched)
    }

    func test_tapCard_gameComplete() {
        vm.setDifficulty(.easy)
        // Match all pairs
        var contentToIndex: [String: [Int]] = [:]
        for (i, card) in vm.cards.enumerated() {
            contentToIndex[card.content, default: []].append(i)
        }

        for (_, indices) in contentToIndex {
            vm.tapCard(at: indices[0])
            vm.tapCard(at: indices[1])
        }

        XCTAssertTrue(vm.isGameComplete)
        XCTAssertEqual(vm.matchedPairs, vm.totalPairs)
    }

    func test_tapCard_outOfBounds_ignored() {
        vm.setDifficulty(.easy)
        vm.tapCard(at: 999)
        XCTAssertEqual(vm.flipCount, 0)
    }

    // MARK: - formattedTime

    func test_formattedTime_zero() {
        vm.setDifficulty(.easy)
        XCTAssertEqual(vm.formattedTime, "0:00.0")
    }

    // MARK: - difficulty switch

    func test_setDifficulty_restartsGame() {
        vm.setDifficulty(.easy)
        vm.tapCard(at: 0)
        vm.setDifficulty(.hard)

        XCTAssertEqual(vm.cards.count, 20)
        XCTAssertEqual(vm.flipCount, 0)
    }
}
