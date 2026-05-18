# PartyGames

iOS party game collection — CardFlip, FanWheel, FingerRoulette.

## Tech Stack

- **Platform**: iOS 16.0+
- **Language**: Swift 5.9, SwiftUI
- **Project**: XcodeGen (`project.yml` → `.xcodeproj`)
- **Lint**: SwiftLint (`.swiftlint.yml`)
- **Quality**: SonarCloud (`.claude/mcp-servers/sonarcloud-mcp.py`)

## Architecture

MVVM with SwiftUI. Each game is a self-contained module under `PartyGames/Games/<GameName>/`.

```
PartyGames/
├── App/           # ContentView, app entry
├── Common/        # AppTheme, ViewExtensions
├── Games/
│   ├── CardFlip/  # CardFlipGameView + CardFlipViewModel
│   ├── FanWheel/  # FanWheelGameView (view owns state inline)
│   └── FingerRoulette/  # FingerRouletteGameView (view owns state inline)
├── Models/        # GameModels — Card, FanWedge, etc.
└── Ads/           # AdConfigManager — remote ad toggle
```

## Conventions

- **Immutability**: `let` by default, `var` only when compiler requires it
- **Value types**: `struct` everywhere; `class` only for identity/reference semantics
- **State**: `@StateObject` / `@ObservedObject` for view models, `@State` for local UI state
- **DI**: Default parameters in init for production, test overrides for mocks
- **Error handling**: Explicit typed throws where possible; no `try!` in production
- **Concurrency**: `@MainActor` on view models; no unstructured `Task {}` without cleanup
- **Secrets**: Keychain for sensitive data, never `UserDefaults`
- **Logging**: `os.Logger` over `print()`

## Before Writing Code

1. Read `.wolf/cerebrum.md` — check Do-Not-Repeat and Key Learnings
2. Follow the MVVM pattern used by existing games
3. Use `AppTheme` constants (colors, fonts, spacing) — never hardcode values
4. Shared button styles are in `ViewExtensions.swift`

## Testing

```bash
# Run unit tests
xcodebuild test -project PartyGames.xcodeproj -scheme PartyGames -destination 'platform=iOS Simulator,name=iPhone 16'

# Generate Xcode project first (if .xcodeproj missing)
xcodegen generate --spec project.yml
```

- Test framework: XCTest
- Unit tests in `PartyGamesUnitTests/`
- UI tests in `PartyGamesUITests/`
- Coverage target: 80%+

## Common Commands

```bash
xcodegen generate --spec project.yml   # Generate .xcodeproj
swiftlint lint --quiet                  # Lint all Swift files
swiftlint lint --fix                    # Auto-fix lint issues
```
