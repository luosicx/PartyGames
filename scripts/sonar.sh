#!/bin/bash
# =============================================================================
# SonarCloud — Analysis Runner for PartyGames
#
# Prerequisites:
#   brew install sonar-scanner swiftlint
#   SonarCloud account + token: https://sonarcloud.io
#
# Usage:
#   export SONAR_TOKEN=<your-sonarcloud-token>
#   export SONAR_ORG=<your-organization-key>
#   ./scripts/sonar.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

SCHEME="PartyGames"
PROJECT="PartyGames.xcodeproj"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData/PartyGames-$(uuidgen | cut -c1-8)"
SIMULATOR="platform=iOS Simulator,name=iPhone 17 Pro"
COVERAGE_DIR="$PROJECT_DIR/coverage"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[sonar]${NC} $1"; }
warn() { echo -e "${YELLOW}[sonar]${NC} $1"; }
err()  { echo -e "${RED}[sonar]${NC} $1"; exit 1; }

# ---- Prerequisite Check ----
check_prereqs() {
    log "Checking prerequisites..."

    if ! command -v sonar-scanner &>/dev/null; then
        err "sonar-scanner not found. Install: brew install sonar-scanner"
    fi

    if ! command -v swiftlint &>/dev/null; then
        warn "swiftlint not installed, skipping lint report"
    fi

    if ! command -v xcodebuild &>/dev/null; then
        err "xcodebuild not found"
    fi

    log "All prerequisites satisfied"
}

# ---- Step 1: Clean DerivedData ----
clean() {
    log "Cleaning derived data..."
    rm -rf "$DERIVED_DATA"
    rm -rf "$COVERAGE_DIR"
    mkdir -p "$COVERAGE_DIR"
}

# ---- Step 2: Build + Run Tests with Coverage ----
run_tests() {
    log "Building and running tests with coverage..."

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$SIMULATOR" \
        -derivedDataPath "$DERIVED_DATA" \
        -enableCodeCoverage YES \
        -quiet \
        2>&1 | tail -20 || {
        warn "Tests failed or no test target configured — skipping coverage"
        return 0
    }

    XCRESULT=$(find "$DERIVED_DATA/Logs/Test" -name "*.xcresult" -type d 2>/dev/null | head -1)
    if [ -z "$XCRESULT" ]; then
        warn "No .xcresult found — skipping coverage"
        return 0
    fi

    echo "$XCRESULT" > "$COVERAGE_DIR/xcresult-path.txt"
    log "Test results: $XCRESULT"
}

# ---- Step 3: Convert Coverage ----
convert_coverage() {
    XCRESULT=$(cat "$COVERAGE_DIR/xcresult-path.txt" 2>/dev/null || echo "")
    if [ -z "$XCRESULT" ] || [ ! -d "$XCRESULT" ]; then
        warn "No xcresult available, skipping coverage conversion"
        return 0
    fi

    log "Converting coverage to SonarQube format..."
    python3 "$SCRIPT_DIR/xcresult-to-sonarqube.py" "$XCRESULT" "$PROJECT_DIR"
}

# ---- Step 4: SwiftLint Report ----
run_swiftlint() {
    if ! command -v swiftlint &>/dev/null; then
        return 0
    fi

    log "Running SwiftLint with SonarQube reporter..."
    swiftlint lint --reporter sonarqube > "$PROJECT_DIR/swiftlint-report.json" 2>/dev/null || true
    log "SwiftLint report: $PROJECT_DIR/swiftlint-report.json"
}

# ---- Step 5: Sonar Scanner (SonarCloud) ----
run_scanner() {
    log "Running sonar-scanner → SonarCloud..."

    local token="${SONAR_TOKEN:-}"
    local org="${SONAR_ORG:-}"

    if [ -z "$token" ]; then
        err "SONAR_TOKEN not set. Generate at: https://sonarcloud.io/account/security"
    fi

    if [ -z "$org" ]; then
        err "SONAR_ORG not set. Find your org key at: https://sonarcloud.io/account/organizations"
    fi

    echo "  Host:  https://sonarcloud.io"
    echo "  Org:   $org"

    sonar-scanner \
        -Dsonar.host.url=https://sonarcloud.io \
        -Dsonar.token="$token" \
        -Dsonar.organization="$org" \
        -Dproject.settings="$PROJECT_DIR/sonar-project.properties"

    log "SonarCloud analysis complete → https://sonarcloud.io/dashboard?id=luosicx_PartyGames"
}

# ---- Step 6: Open Dashboard ----
open_dashboard() {
    log "Opening SonarCloud dashboard..."
    open "https://sonarcloud.io/dashboard?id=luosicx_PartyGames" 2>/dev/null || true
}

# ---- Main ----
main() {
    echo ""
    echo "=============================================="
    echo "  SonarCloud Analysis — PartyGames"
    echo "=============================================="
    echo ""

    check_prereqs
    clean
    run_tests
    convert_coverage
    run_swiftlint
    run_scanner
    open_dashboard

    echo ""
    log "Done."
}

main
