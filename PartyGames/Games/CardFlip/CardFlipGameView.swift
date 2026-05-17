import SwiftUI

struct CardFlipGameView: View {
    @StateObject private var viewModel = CardFlipViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            difficultyPicker
            gameGrid
            Spacer(minLength: 60)
        }
        .padding(.horizontal)
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear { viewModel.startGame() }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(loc("cardflip_title"))
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.accent)

            HStack(spacing: 24) {
                statBadge(label: loc("cardflip_flips"), value: "\(viewModel.flipCount)")
                statBadge(label: loc("cardflip_matched"), value: "\(viewModel.matchedPairs)/\(viewModel.totalPairs)")
                statBadge(label: loc("cardflip_time"), value: viewModel.formattedTime)
            }
        }
        .padding(.vertical, 12)
    }

    private func statBadge(label: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text(label)
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Difficulty
    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            ForEach(FlipDifficulty.allCases) { difficulty in
                Button(difficulty.displayName) {
                    viewModel.setDifficulty(difficulty)
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(viewModel.difficulty == difficulty ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewModel.difficulty == difficulty ? AppTheme.primary : AppTheme.surface)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Grid
    private var gameGrid: some View {
        let spacing: CGFloat = 8
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: viewModel.columns)

        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { idx, card in
                CardCell(card: card)
                    .onTapGesture { viewModel.tapCard(at: idx) }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Single Card
struct CardCell: View {
    let card: CardItem

    var body: some View {
        ZStack {
            if card.isFlipped || card.isMatched {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.isMatched ? AppTheme.success.opacity(0.3) : AppTheme.secondary.opacity(0.3))
                Text(card.content)
                    .font(.system(size: 36))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBack)
                Text("?")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(card.isMatched ? AppTheme.success : Color.white.opacity(0.15), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: card.isFlipped)
        .animation(.easeInOut(duration: 0.3), value: card.isMatched)
        .opacity(card.isMatched ? 0.5 : 1.0)
    }
}
