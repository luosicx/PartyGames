import SwiftUI

enum AppTheme {
    // MARK: - Colors
    static let primary    = Color(hex: "FF6B6B")
    static let secondary  = Color(hex: "4ECDC4")
    static let accent     = Color(hex: "FFE66D")
    static let background = Color(hex: "1A1A2E")
    static let surface    = Color(hex: "16213E")
    static let cardBack   = Color(hex: "7B2D8E")
    static let gold       = Color(hex: "FFD700")
    static let success    = Color(hex: "00B894")
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.7)

    static let wheelColors: [Color] = [
        Color(hex: "FF6B6B"),
        Color(hex: "4ECDC4"),
        Color(hex: "FFE66D"),
        Color(hex: "A29BFE"),
        Color(hex: "FD79A8"),
        Color(hex: "00B894"),
        Color(hex: "FDCB6E"),
        Color(hex: "E17055"),
    ]

    static let cardEmojis = [
        "🎉", "🎈", "🎊", "🎂", "🍕", "🍔",
        "🌮", "🍩", "🎵", "🎸", "🎯", "🎲",
        "👑", "💎", "🔥", "⭐", "🦄", "🌈",
    ]

    // MARK: - Typography
    static let titleFont    = Font.system(.largeTitle, design: .rounded, weight: .heavy)
    static let headlineFont = Font.system(.title2, design: .rounded, weight: .bold)
    static let bodyFont     = Font.system(.body, design: .rounded, weight: .medium)
    static let captionFont  = Font.system(.caption, design: .rounded, weight: .regular)
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            red:   Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8)  / 255.0,
            blue:  Double(rgbValue & 0x0000FF)         / 255.0
        )
    }
}

// MARK: - Localized String Helper
func loc(_ key: String) -> LocalizedStringKey {
    LocalizedStringKey(key)
}

func locString(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
