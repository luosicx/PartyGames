# PartyGames

A SwiftUI-based party game app with custom ad system, multi-language support, and zero third-party dependencies.

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9

## Project Structure

```
PartyGames/
├── App/
│   ├── PartyGamesApp.swift          # App entry point
│   └── ContentView.swift            # Main tab view
├── Ads/
│   ├── AdConfigManager.swift        # Remote ad config (fetch/cache/toggle)
│   ├── SplashAdView.swift           # Full-screen splash ad
│   └── BannerAdView.swift           # Bottom banner ad
├── Common/
│   ├── AppTheme.swift               # Colors, fonts, helpers
│   └── ViewExtensions.swift         # Button styles, animations
├── Games/
│   ├── CardFlip/
│   │   ├── CardFlipGameView.swift   # Memory card matching game
│   │   └── CardFlipViewModel.swift
│   ├── FanWheel/
│   │   ├── FanWheelGameView.swift   # Prize/challenge spinning wheel
│   │   └── FanWheelViewModel.swift
│   └── FingerRoulette/
│       ├── FingerRouletteGameView.swift  # Truth-or-dare roulette
│       └── FingerRouletteViewModel.swift
├── Models/
│   └── GameModels.swift             # Shared model types
└── Info.plist
PartyGamesUnitTests/                  # Unit tests
PartyGamesUITests/                    # UI tests
project.yml                           # XcodeGen spec
```

## Architecture

- **MVVM + @MainActor**: ViewModels are `@MainActor`-isolated `ObservableObject`s
- **Custom Ads**: Remote-configurable via JSON URL, default OFF, always user-dismissible
- **i18n**: `loc()` for `LocalizedStringKey`, `locString()` for `String` interpolation
- **No third-party SDKs**: SPM-only, no CocoaPods/Carthage

## Build

```bash
# Generate Xcode project
xcodegen generate --spec project.yml

# Open
open PartyGames.xcodeproj

# Build
xcodebuild build -project PartyGames.xcodeproj -scheme PartyGames -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Tests

```bash
# Unit tests (56 tests)
xcodebuild test -project PartyGames.xcodeproj -scheme PartyGames \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:PartyGamesUnitTests

# UI tests
xcodebuild test -project PartyGames.xcodeproj -scheme PartyGames \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:PartyGamesUITests
```

## SonarCloud

SonarCloud MCP server for fetching analysis results directly in Claude Code.

**Setup:**

```bash
python3 .claude/mcp-servers/sonarcloud-mcp.py
```

Requires env vars: `SONARCLOUD_TOKEN`, `SONARCLOUD_ORG`

## License

MIT
