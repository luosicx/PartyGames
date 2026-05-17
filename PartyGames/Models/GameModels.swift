import SwiftUI

// MARK: - Card Flip Models

struct CardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    var isFlipped: Bool = false
    var isMatched: Bool = false

    static func == (lhs: CardItem, rhs: CardItem) -> Bool { lhs.id == rhs.id }
}

enum FlipDifficulty: String, CaseIterable, Identifiable {
    case easy   = "difficulty_easy"
    case medium = "difficulty_medium"
    case hard   = "difficulty_hard"

    var id: String { rawValue }

    var pairs: Int {
        switch self {
        case .easy:   return 6
        case .medium: return 8
        case .hard:   return 10
        }
    }

    var columns: Int {
        switch self {
        case .easy:   return 3
        case .medium: return 4
        case .hard:   return 4
        }
    }

    var displayName: String {
        switch self {
        case .easy:   return locString("difficulty_easy")
        case .medium: return locString("difficulty_medium")
        case .hard:   return locString("difficulty_hard")
        }
    }
}

// MARK: - Roulette Models

struct RouletteSegment: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}

struct RoulettePreset: Identifiable {
    let id = UUID()
    let name: String
    let segments: [RouletteSegment]

    static let truthOrDare = RoulettePreset(
        name: "Truth or Dare",
        segments: [
            RouletteSegment(label: locString("truth"), color: AppTheme.wheelColors[0]),
            RouletteSegment(label: locString("dare"), color: AppTheme.wheelColors[1]),
            RouletteSegment(label: locString("truth"), color: AppTheme.wheelColors[2]),
            RouletteSegment(label: locString("dare"), color: AppTheme.wheelColors[3]),
            RouletteSegment(label: locString("double_dare"), color: AppTheme.wheelColors[4]),
            RouletteSegment(label: locString("truth"), color: AppTheme.wheelColors[5]),
            RouletteSegment(label: locString("dare"), color: AppTheme.wheelColors[6]),
            RouletteSegment(label: locString("wildcard"), color: AppTheme.wheelColors[7])
        ]
    )

    static let partyMoves = RoulettePreset(
        name: "Party Moves",
        segments: [
            RouletteSegment(label: "💃", color: AppTheme.wheelColors[0]),
            RouletteSegment(label: "🕺", color: AppTheme.wheelColors[1]),
            RouletteSegment(label: "🤸", color: AppTheme.wheelColors[2]),
            RouletteSegment(label: "🎤", color: AppTheme.wheelColors[3]),
            RouletteSegment(label: "🪩", color: AppTheme.wheelColors[4]),
            RouletteSegment(label: "💪", color: AppTheme.wheelColors[5]),
            RouletteSegment(label: "🙌", color: AppTheme.wheelColors[6]),
            RouletteSegment(label: "🎭", color: AppTheme.wheelColors[7])
        ]
    )
}

// MARK: - Fan Wheel Models

struct WheelSegment: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
    let icon: String
}

struct FanWheelPreset: Identifiable {
    let id = UUID()
    let name: String
    let segments: [WheelSegment]

    static let classic = FanWheelPreset(
        name: "Classic Prizes",
        segments: [
            WheelSegment(label: locString("prize_big"), color: AppTheme.wheelColors[0], icon: "gift.fill"),
            WheelSegment(label: locString("prize_small"), color: AppTheme.wheelColors[1], icon: "gift"),
            WheelSegment(label: locString("prize_nothing"), color: AppTheme.wheelColors[2], icon: "xmark"),
            WheelSegment(label: locString("prize_big"), color: AppTheme.wheelColors[3], icon: "gift.fill"),
            WheelSegment(label: locString("prize_small"), color: AppTheme.wheelColors[4], icon: "gift"),
            WheelSegment(label: locString("prize_jackpot"), color: AppTheme.wheelColors[5], icon: "star.fill")
        ]
    )

    static let challenges = FanWheelPreset(
        name: "Challenges",
        segments: [
            WheelSegment(
                label: locString("challenge_sing"),
                color: AppTheme.wheelColors[0], icon: "music.mic"
            ),
            WheelSegment(
                label: locString("challenge_dance"),
                color: AppTheme.wheelColors[1], icon: "figure.dance"
            ),
            WheelSegment(
                label: locString("challenge_joke"),
                color: AppTheme.wheelColors[2], icon: "theatermasks.fill"
            ),
            WheelSegment(
                label: locString("challenge_mime"),
                color: AppTheme.wheelColors[3], icon: "hand.raised.fill"
            ),
            WheelSegment(
                label: locString("challenge_story"),
                color: AppTheme.wheelColors[4], icon: "book.fill"
            ),
            WheelSegment(
                label: locString("challenge_impress"),
                color: AppTheme.wheelColors[5], icon: "crown.fill"
            )
        ]
    )
}
