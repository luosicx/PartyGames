import SwiftUI

@MainActor
final class CardFlipViewModel: ObservableObject {
    @Published var cards: [CardItem] = []
    @Published var difficulty: FlipDifficulty = .easy
    @Published var flipCount = 0
    @Published var matchedPairs = 0
    @Published var isGameComplete = false
    @Published var elapsedTime: TimeInterval = 0

    private var firstFlippedIndex: Int?
    private var isProcessing = false
    private var timer: Timer?
    private var gameStartTime: Date?

    var totalPairs: Int { difficulty.pairs }
    var columns: Int { difficulty.columns }

    func startGame() {
        timer?.invalidate()
        let emojis = AppTheme.cardEmojis.shuffled().prefix(difficulty.pairs)
        var deck = emojis.flatMap { emoji in
            [CardItem(content: emoji), CardItem(content: emoji)]
        }.shuffled()

        // Reset
        for i in deck.indices {
            deck[i].isFlipped = false
            deck[i].isMatched = false
        }

        cards = deck
        flipCount = 0
        matchedPairs = 0
        isGameComplete = false
        elapsedTime = 0
        firstFlippedIndex = nil
        isProcessing = false
        gameStartTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.gameStartTime, !self.isGameComplete else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func tapCard(at index: Int) {
        guard !isProcessing,
              index < cards.count,
              !cards[index].isFlipped,
              !cards[index].isMatched
        else { return }

        cards[index].isFlipped = true
        flipCount += 1

        guard let first = firstFlippedIndex else {
            firstFlippedIndex = index
            return
        }

        isProcessing = true
        let second = index

        if cards[first].content == cards[second].content {
            cards[first].isMatched = true
            cards[second].isMatched = true
            matchedPairs += 1
            firstFlippedIndex = nil
            isProcessing = false

            if matchedPairs == totalPairs {
                isGameComplete = true
                timer?.invalidate()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.cards[first].isFlipped = false
                self?.cards[second].isFlipped = false
                self?.firstFlippedIndex = nil
                self?.isProcessing = false
            }
        }
    }

    func setDifficulty(_ d: FlipDifficulty) {
        difficulty = d
        startGame()
    }

    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let tenths = Int((elapsedTime * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}
